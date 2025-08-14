#!/usr/bin/env node

/**
 * iOS Simulator Manager MCP Tool
 * Automates iOS simulator launch, app deployment, and monitoring
 */

const { exec, spawn } = require('child_process');
import fs from 'fs';
const fsPromises = fsPromises;
import path from 'path';
import { promisify } from 'util';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const execAsync = promisify(exec);
const { XMLParser } = require('fast-xml-parser');

class IOSSimulatorManager {
    constructor() {
        this.projectRoot = path.resolve(__dirname, '../..');
        this.iosPath = path.join(this.projectRoot, 'mobile/ios');
        this.logProcess = null;
        this.activeSimulator = null;
        this.wdaPort = 8100;
        this.wdaSession = null;
    }

    /**
     * Get list of available simulators
     */
    async listSimulators() {
        try {
            const { stdout } = await execAsync('xcrun simctl list devices available -j');
            const data = JSON.parse(stdout);
            
            const simulators = [];
            for (const [runtime, devices] of Object.entries(data.devices)) {
                if (runtime.includes('iOS')) {
                    for (const device of devices) {
                        if (device.state === 'Booted' || device.isAvailable) {
                            simulators.push({
                                name: device.name,
                                udid: device.udid,
                                state: device.state,
                                runtime: runtime.split('.').pop()
                            });
                        }
                    }
                }
            }
            return simulators;
        } catch (error) {
            throw new Error(`Failed to list simulators: ${error.message}`);
        }
    }

    /**
     * Boot a specific simulator or use default
     */
    async bootSimulator(deviceName = null) {
        try {
            const simulators = await this.listSimulators();
            
            // Check if any simulator is already booted
            let targetSimulator = simulators.find(sim => sim.state === 'Booted');
            
            if (!targetSimulator) {
                // Find target simulator by name or use first available
                if (deviceName) {
                    targetSimulator = simulators.find(sim => 
                        sim.name.toLowerCase().includes(deviceName.toLowerCase())
                    );
                } else {
                    // Default to iPhone 16 or latest available
                    targetSimulator = simulators.find(sim => sim.name.includes('iPhone 16')) ||
                                    simulators.find(sim => sim.name.includes('iPhone 15')) ||
                                    simulators[0];
                }
                
                if (!targetSimulator) {
                    throw new Error('No suitable simulator found');
                }
                
                console.log(`🚀 Booting ${targetSimulator.name}...`);
                await execAsync(`xcrun simctl boot ${targetSimulator.udid}`);
                
                // Wait for boot to complete
                await new Promise(resolve => setTimeout(resolve, 3000));
            } else {
                console.log(`✅ Using already booted simulator: ${targetSimulator.name}`);
            }
            
            this.activeSimulator = targetSimulator;
            
            // Open Simulator app
            await execAsync('open -a Simulator');
            
            return targetSimulator;
        } catch (error) {
            throw new Error(`Failed to boot simulator: ${error.message}`);
        }
    }

    /**
     * Build the iOS app
     */
    async buildApp() {
        try {
            console.log('🔨 Building iOS app...');
            
            const buildCommand = `cd "${this.iosPath}" && xcodebuild \
                -scheme RoadtripCopilot \
                -configuration Debug \
                -sdk iphonesimulator \
                -derivedDataPath build \
                -destination 'platform=iOS Simulator,name=${this.activeSimulator.name}' \
                build`;
            
            const { stdout, stderr } = await execAsync(buildCommand, { maxBuffer: 10 * 1024 * 1024 });
            
            if (stderr && !stderr.includes('warning')) {
                console.warn('Build warnings:', stderr);
            }
            
            console.log('✅ Build successful');
            return true;
        } catch (error) {
            throw new Error(`Build failed: ${error.message}`);
        }
    }

    /**
     * Install and launch the app on simulator
     */
    async installAndLaunchApp() {
        try {
            console.log('📱 Installing app on simulator...');
            
            // Find the built app
            const appPath = path.join(
                this.iosPath,
                'build/Build/Products/Debug-iphonesimulator/RoadtripCopilot.app'
            );
            
            // Verify app exists
            try {
                await fs.access(appPath);
            } catch {
                throw new Error(`App not found at: ${appPath}. Make sure to build the app first.`);
            }
            
            // Install the app with timeout
            console.log(`Installing from: ${appPath}`);
            const installCmd = `xcrun simctl install ${this.activeSimulator.udid} "${appPath}"`;
            await this.execWithTimeout(installCmd, 30000, 'App installation');
            console.log('✅ App installed');
            
            // Wait a moment for installation to settle
            await new Promise(resolve => setTimeout(resolve, 2000));
            
            // Launch the app with timeout
            console.log('🚀 Launching app...');
            const launchCmd = `xcrun simctl launch ${this.activeSimulator.udid} com.hmi2.roadtrip-copilot`;
            const launchResult = await this.execWithTimeout(launchCmd, 15000, 'App launch');
            
            if (launchResult.stdout.includes(':')) {
                const processId = launchResult.stdout.split(':')[1].trim();
                console.log(`✅ App launched successfully (PID: ${processId})`);
                
                // Wait a moment for app to initialize
                await new Promise(resolve => setTimeout(resolve, 3000));
                
                // Verify app is still running
                try {
                    const statusResult = await this.execWithTimeout(
                        `xcrun simctl spawn ${this.activeSimulator.udid} ps aux | grep com.hmi2.roadtrip-copilot | grep -v grep`,
                        5000,
                        'App status check'
                    );
                    
                    if (statusResult.stdout.trim()) {
                        console.log('✅ App is running successfully');
                        return true;
                    } else {
                        console.warn('⚠️  App may have crashed after launch');
                        return false;
                    }
                } catch (statusError) {
                    console.warn('⚠️  Could not verify app status, but launch appeared successful');
                    return true;
                }
            } else {
                throw new Error('Launch command succeeded but no process ID returned');
            }
        } catch (error) {
            console.error(`❌ Install/Launch failed: ${error.message}`);
            throw error;
        }
    }

    /**
     * Execute command with timeout and proper error handling
     */
    async execWithTimeout(command, timeout, operation) {
        return new Promise((resolve, reject) => {
            const childProcess = exec(command, (error, stdout, stderr) => {
                if (error) {
                    reject(new Error(`${operation} failed: ${error.message}`));
                } else {
                    resolve({ stdout, stderr });
                }
            });

            const timer = setTimeout(() => {
                childProcess.kill('SIGKILL');
                reject(new Error(`${operation} timed out after ${timeout}ms`));
            }, timeout);

            childProcess.on('exit', () => {
                clearTimeout(timer);
            });
        });
    }

    /**
     * Enhanced app launch validation and crash detection
     */
    async validateAppLaunch(timeoutMs = 30000) {
        console.log('🔍 Validating app launch and checking for crashes...');
        
        try {
            // Start crash log monitoring
            const crashPromise = this.monitorForCrashes();
            
            // Launch the app
            const launchSuccess = await this.installAndLaunchApp();
            
            if (!launchSuccess) {
                return {
                    success: false,
                    error: 'App failed to launch or crashed immediately',
                    crashes: []
                };
            }
            
            // Wait for potential crashes
            console.log('⏳ Waiting for app stability check (15 seconds)...');
            await new Promise(resolve => setTimeout(resolve, 15000));
            
            // Check for any crashes that occurred
            const crashes = await crashPromise;
            
            if (crashes.length > 0) {
                return {
                    success: false,
                    error: `App crashed during launch: ${crashes[0].reason}`,
                    crashes: crashes
                };
            }
            
            // Final verification that app is still running
            try {
                const isRunning = await this.isAppRunning();
                if (!isRunning) {
                    return {
                        success: false,
                        error: 'App stopped running after initial launch',
                        crashes: []
                    };
                }
                
                console.log('✅ App launch validation successful - no crashes detected');
                return {
                    success: true,
                    error: null,
                    crashes: []
                };
                
            } catch (verifyError) {
                return {
                    success: false,
                    error: `Could not verify app is running: ${verifyError.message}`,
                    crashes: []
                };
            }
            
        } catch (error) {
            return {
                success: false,
                error: error.message,
                crashes: []
            };
        }
    }
    
    /**
     * Monitor for crashes during app launch
     */
    async monitorForCrashes() {
        return new Promise((resolve) => {
            const crashes = [];
            const timeout = setTimeout(() => {
                resolve(crashes);
            }, 20000); // Monitor for 20 seconds
            
            // Monitor crash logs
            const crashMonitor = spawn('xcrun', [
                'simctl',
                'spawn',
                this.activeSimulator.udid,
                'log',
                'stream',
                '--predicate',
                'eventType == "logEvent" AND eventMessage CONTAINS "CRASHED" OR eventMessage CONTAINS "SIGABRT" OR eventMessage CONTAINS "fatal error"'
            ]);
            
            crashMonitor.stdout.on('data', (data) => {
                const lines = data.toString().split('\n');
                lines.forEach(line => {
                    if (line.includes('CRASHED') || line.includes('SIGABRT') || line.includes('fatal error')) {
                        console.error(`💥 CRASH DETECTED: ${line}`);
                        crashes.push({
                            timestamp: new Date().toISOString(),
                            reason: line.trim()
                        });
                    }
                });
            });
            
            // Auto-cleanup
            setTimeout(() => {
                crashMonitor.kill();
                clearTimeout(timeout);
                resolve(crashes);
            }, 20000);
        });
    }
    
    /**
     * Check if app is currently running
     */
    async isAppRunning() {
        try {
            const result = await this.execWithTimeout(
                `xcrun simctl spawn ${this.activeSimulator.udid} ps aux | grep "com.hmi2.roadtrip-copilot" | grep -v grep`,
                5000,
                'App running check'
            );
            return result.stdout.trim().length > 0;
        } catch (error) {
            console.warn(`Could not check app status: ${error.message}`);
            return false;
        }
    }

    /**
     * Start monitoring simulator logs
     */
    async startLogMonitoring(filter = 'Roadtrip-Copilot') {
        try {
            console.log(`📋 Starting log monitoring (filter: ${filter})...`);
            
            // Ensure we have an active simulator
            if (!this.activeSimulator || !this.activeSimulator.udid) {
                // Get the booted simulator
                const simulators = await this.listSimulators();
                this.activeSimulator = simulators.find(sim => sim.state === 'Booted');
                if (!this.activeSimulator) {
                    throw new Error('No booted simulator found');
                }
            }
            
            // Stop any existing log process
            if (this.logProcess) {
                this.logProcess.kill();
            }
            
            console.log(`🔍 Monitoring logs on ${this.activeSimulator.name} (${this.activeSimulator.udid})`);
            
            // Start new log streaming - use 'booted' keyword for simplicity
            // Use subsystem predicate for os_log messages
            const predicate = `subsystem == "com.hmi2.roadtrip-copilot" OR processImagePath CONTAINS "RoadtripCopilot"`;
            
            this.logProcess = spawn('xcrun', [
                'simctl',
                'spawn',
                'booted',
                'log',
                'stream',
                '--level', 'info',
                '--style', 'compact',
                '--predicate',
                predicate
            ]);
            
            this.logProcess.stdout.on('data', (data) => {
                const lines = data.toString().split('\n');
                lines.forEach(line => {
                    if (line.trim()) {
                        // Format and display relevant logs with special attention to MODEL TEST
                        if (line.includes('🧪') || line.includes('MODEL TEST')) {
                            console.log(`\n🧪 MODEL TEST: ${line}\n`);
                        } else if (line.includes('✅') && line.includes('MODEL TEST')) {
                            console.log(`\n✅ MODEL TEST SUCCESS: ${line}\n`);
                        } else if (line.includes('🎉') && line.includes('MODEL TEST')) {
                            console.log(`\n🎉 MODEL TEST COMPLETE: ${line}\n`);
                        } else if (line.includes('Gemma') || line.includes('gemma')) {
                            console.log(`🤖 AI: ${line}`);
                        } else if (line.includes('who are you')) {
                            console.log(`💬 Query: ${line}`);
                        } else if (line.includes('ERROR') || line.includes('FATAL')) {
                            console.error(`❌ ${line}`);
                        } else if (line.includes('WARNING')) {
                            console.warn(`⚠️  ${line}`);
                        } else if (line.includes('Speech') || line.includes('CarPlay') || line.includes('Destination')) {
                            console.log(`🎯 ${line}`);
                        } else {
                            console.log(`   ${line}`);
                        }
                    }
                });
            });
            
            this.logProcess.stderr.on('data', (data) => {
                console.error(`Log error: ${data}`);
            });
            
            console.log('✅ Log monitoring started');
            return true;
        } catch (error) {
            throw new Error(`Failed to start log monitoring: ${error.message}`);
        }
    }

    /**
     * Take a screenshot of the simulator
     */
    async takeScreenshot(outputPath = null) {
        try {
            if (!outputPath) {
                const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
                outputPath = path.join(this.projectRoot, `screenshot-${timestamp}.png`);
            }
            
            console.log('📸 Taking screenshot...');
            await execAsync(`xcrun simctl io ${this.activeSimulator.udid} screenshot "${outputPath}"`);
            console.log(`✅ Screenshot saved to: ${outputPath}`);
            
            return outputPath;
        } catch (error) {
            throw new Error(`Failed to take screenshot: ${error.message}`);
        }
    }

    /**
     * Record video of the simulator
     */
    async startRecording(outputPath = null) {
        try {
            if (!outputPath) {
                const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
                outputPath = path.join(this.projectRoot, `recording-${timestamp}.mp4`);
            }
            
            console.log('🎥 Starting video recording...');
            
            // Start recording in background
            const recordProcess = spawn('xcrun', [
                'simctl',
                'io',
                this.activeSimulator.udid,
                'recordVideo',
                outputPath
            ], { detached: true });
            
            console.log(`✅ Recording started. Press Ctrl+C in the simulator to stop.`);
            console.log(`   Output will be saved to: ${outputPath}`);
            
            return { process: recordProcess, outputPath };
        } catch (error) {
            throw new Error(`Failed to start recording: ${error.message}`);
        }
    }

    /**
     * Simulate user interactions
     */
    async simulateTap(x, y) {
        try {
            await execAsync(`xcrun simctl io ${this.activeSimulator.udid} tap ${x} ${y}`);
            console.log(`✅ Tapped at (${x}, ${y})`);
            return true;
        } catch (error) {
            throw new Error(`Failed to simulate tap: ${error.message}`);
        }
    }

    /**
     * Type text in the simulator
     */
    async typeText(text) {
        try {
            await execAsync(`xcrun simctl io ${this.activeSimulator.udid} type "${text}"`);
            console.log(`✅ Typed: "${text}"`);
            return true;
        } catch (error) {
            throw new Error(`Failed to type text: ${error.message}`);
        }
    }

    /**
     * Get app state
     */
    async getAppState() {
        try {
            const { stdout } = await execAsync(
                `xcrun simctl get_app_container ${this.activeSimulator.udid} com.hmi2.roadtrip-copilot`
            );
            
            const isInstalled = stdout && stdout.trim().length > 0;
            
            if (isInstalled) {
                // Check if app is running
                const { stdout: psOutput } = await execAsync(
                    `xcrun simctl spawn ${this.activeSimulator.udid} launchctl list | grep com.hmi2.roadtrip-copilot`
                ).catch(() => ({ stdout: '' }));
                
                const isRunning = psOutput && psOutput.trim().length > 0;
                
                return {
                    installed: true,
                    running: isRunning,
                    simulator: this.activeSimulator
                };
            }
            
            return {
                installed: false,
                running: false,
                simulator: this.activeSimulator
            };
        } catch (error) {
            return {
                installed: false,
                running: false,
                simulator: this.activeSimulator,
                error: error.message
            };
        }
    }

    /**
     * Get recent logs from the simulator
     */
    async getRecentLogs(filter = 'RoadtripCopilot', seconds = 30) {
        try {
            console.log(`📋 Getting recent logs (filter: ${filter}, last ${seconds}s)...`);
            
            const { stdout } = await execAsync(`xcrun simctl spawn booted log show --last ${seconds}s --style compact --predicate 'processImagePath CONTAINS "${filter}"' 2>/dev/null || echo "No logs found"`);
            
            // Parse and display relevant logs
            const logLines = stdout.split('\n');
            let foundModelTest = false;
            
            logLines.forEach(line => {
                if (line.includes('MODEL TEST') || line.includes('🧪')) {
                    console.log(`\n🧪 MODEL TEST: ${line}\n`);
                    foundModelTest = true;
                } else if (line.includes('✅') && line.includes('MODEL')) {
                    console.log(`\n✅ SUCCESS: ${line}\n`);
                } else if (line.includes('Gemma') || line.includes('who are you')) {
                    console.log(`🤖 AI: ${line}`);
                } else if (line.includes('ERROR')) {
                    console.error(`❌ ${line}`);
                }
            });
            
            if (!foundModelTest) {
                console.log('⚠️  No MODEL TEST logs found in recent output');
                console.log('📝 Checking for any app output...');
                
                // Try alternative log collection
                const { stdout: altLogs } = await execAsync(`xcrun simctl spawn booted log stream --last 10s --style compact | grep -i "roadtrip\\|gemma\\|model" | head -20`).catch(() => ({ stdout: '' }));
                if (altLogs) {
                    console.log('Alternative logs:', altLogs);
                }
            }
            
            return stdout;
        } catch (error) {
            console.error(`Failed to get recent logs: ${error.message}`);
            return null;
        }
    }
    
    /**
     * Stop log monitoring
     */
    stopLogMonitoring() {
        if (this.logProcess) {
            this.logProcess.kill();
            this.logProcess = null;
            console.log('✅ Log monitoring stopped');
        }
    }

    /**
     * Reset simulator
     */
    async resetSimulator() {
        try {
            console.log('🔄 Resetting simulator...');
            await execAsync(`xcrun simctl erase ${this.activeSimulator.udid}`);
            console.log('✅ Simulator reset complete');
            return true;
        } catch (error) {
            throw new Error(`Failed to reset simulator: ${error.message}`);
        }
    }

    /**
     * Initialize WebDriverAgent connection for advanced UI control
     */
    async initializeWDA() {
        try {
            // Check if WDA is already running
            const isRunning = await this.isWDARunning();
            if (!isRunning) {
                console.log('🔧 Starting WebDriverAgent...');
                await this.startWDA();
            }
            
            // Create WDA session
            const sessionResponse = await fetch(`http://localhost:${this.wdaPort}/session`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ capabilities: { alwaysMatch: { platformName: 'iOS' } } })
            });
            
            if (sessionResponse.ok) {
                const sessionData = await sessionResponse.json();
                this.wdaSession = sessionData.value.sessionId;
                console.log('✅ WebDriverAgent session established');
                return true;
            }
        } catch (error) {
            console.warn(`⚠️  WebDriverAgent initialization failed: ${error.message}`);
            return false;
        }
    }

    /**
     * Check if WebDriverAgent is running
     */
    async isWDARunning() {
        try {
            const response = await fetch(`http://localhost:${this.wdaPort}/status`, { timeout: 2000 });
            const data = await response.json();
            return response.ok && data.value?.ready === true;
        } catch (error) {
            return false;
        }
    }

    /**
     * Start WebDriverAgent
     */
    async startWDA() {
        try {
            // Check if WDA is installed
            const apps = await this.getInstalledApps();
            const wdaApp = apps.find(app => app.includes('WebDriverAgentRunner'));
            
            if (wdaApp) {
                await execAsync(`xcrun simctl launch ${this.activeSimulator.udid} com.facebook.WebDriverAgentRunner.xctrunner`);
                
                // Wait for WDA to start
                for (let i = 0; i < 30; i++) {
                    if (await this.isWDARunning()) {
                        return true;
                    }
                    await new Promise(resolve => setTimeout(resolve, 1000));
                }
            }
        } catch (error) {
            console.warn(`Could not start WebDriverAgent: ${error.message}`);
        }
        return false;
    }

    /**
     * Get installed apps on simulator
     */
    async getInstalledApps() {
        try {
            const { stdout } = await execAsync(`xcrun simctl listapps ${this.activeSimulator.udid}`);
            return stdout.split('\n').filter(line => line.includes('CFBundleIdentifier'));
        } catch (error) {
            return [];
        }
    }

    /**
     * Get accessibility tree from app
     */
    async getAccessibilityTree() {
        if (!this.wdaSession) {
            console.log('🔧 Initializing WebDriverAgent for accessibility tree...');
            await this.initializeWDA();
        }

        if (this.wdaSession) {
            try {
                const response = await fetch(`http://localhost:${this.wdaPort}/source?format=json`);
                if (response.ok) {
                    const data = await response.json();
                    return this.parseAccessibilityTree(data.value);
                }
            } catch (error) {
                console.warn(`Failed to get accessibility tree: ${error.message}`);
            }
        }
        
        // Fallback to screenshot-based element detection
        return await this.getElementsFromScreenshot();
    }

    /**
     * Parse accessibility tree into structured elements
     */
    parseAccessibilityTree(tree, elements = []) {
        const acceptedTypes = ['TextField', 'Button', 'Switch', 'Icon', 'SearchField', 'StaticText', 'Image'];
        
        if (tree.type && acceptedTypes.includes(tree.type)) {
            if (tree.isVisible === '1' && tree.rect && tree.rect.x >= 0 && tree.rect.y >= 0) {
                elements.push({
                    type: tree.type,
                    label: tree.label || '',
                    name: tree.name || '',
                    value: tree.value || '',
                    identifier: tree.rawIdentifier || '',
                    rect: {
                        x: tree.rect.x,
                        y: tree.rect.y,
                        width: tree.rect.width,
                        height: tree.rect.height
                    },
                    enabled: tree.enabled !== '0',
                    visible: tree.isVisible === '1'
                });
            }
        }
        
        if (tree.children && Array.isArray(tree.children)) {
            tree.children.forEach(child => this.parseAccessibilityTree(child, elements));
        }
        
        return elements;
    }

    /**
     * Tap on element by coordinates or accessibility properties
     */
    async tapElement(selector) {
        if (!this.wdaSession) {
            await this.initializeWDA();
        }

        if (this.wdaSession) {
            try {
                if (typeof selector === 'object' && selector.x !== undefined && selector.y !== undefined) {
                    // Tap by coordinates
                    await this.tapCoordinates(selector.x, selector.y);
                } else {
                    // Find element by properties and tap
                    const elements = await this.getAccessibilityTree();
                    const element = elements.find(el => 
                        el.label.includes(selector) ||
                        el.name.includes(selector) ||
                        el.identifier.includes(selector)
                    );
                    
                    if (element) {
                        const centerX = element.rect.x + element.rect.width / 2;
                        const centerY = element.rect.y + element.rect.height / 2;
                        await this.tapCoordinates(centerX, centerY);
                        console.log(`✅ Tapped element: ${element.label || element.name}`);
                        return element;
                    } else {
                        console.warn(`❌ Element not found: ${selector}`);
                        return null;
                    }
                }
            } catch (error) {
                console.error(`Failed to tap element: ${error.message}`);
                return null;
            }
        }
    }

    /**
     * Tap at specific coordinates using WebDriverAgent
     */
    async tapCoordinates(x, y) {
        if (!this.wdaSession) {
            await this.initializeWDA();
        }

        if (this.wdaSession) {
            try {
                const response = await fetch(`http://localhost:${this.wdaPort}/session/${this.wdaSession}/actions`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        actions: [{
                            type: 'pointer',
                            id: 'finger1',
                            parameters: { pointerType: 'touch' },
                            actions: [
                                { type: 'pointerMove', duration: 0, x, y },
                                { type: 'pointerDown', button: 0 },
                                { type: 'pause', duration: 100 },
                                { type: 'pointerUp', button: 0 }
                            ]
                        }]
                    })
                });
                
                if (response.ok) {
                    console.log(`✅ Tapped at coordinates (${x}, ${y})`);
                    return true;
                }
            } catch (error) {
                console.warn(`Failed to tap coordinates: ${error.message}`);
                // Fallback to simctl tap
                return await this.simulateTap(x, y);
            }
        }
        return false;
    }

    /**
     * Enter text using WebDriverAgent
     */
    async enterText(text) {
        if (!this.wdaSession) {
            await this.initializeWDA();
        }

        if (this.wdaSession) {
            try {
                const response = await fetch(`http://localhost:${this.wdaPort}/session/${this.wdaSession}/wda/keys`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ value: [text] })
                });
                
                if (response.ok) {
                    console.log(`✅ Entered text: "${text}"`);
                    return true;
                }
            } catch (error) {
                console.warn(`Failed to enter text via WDA: ${error.message}`);
                // Fallback to simctl
                return await this.typeText(text);
            }
        }
        return false;
    }

    /**
     * Swipe gesture using WebDriverAgent
     */
    async swipeGesture(direction, startX, startY, distance = 200) {
        if (!this.wdaSession) {
            await this.initializeWDA();
        }

        if (this.wdaSession) {
            try {
                let endX = startX;
                let endY = startY;
                
                switch (direction) {
                    case 'up':
                        endY -= distance;
                        break;
                    case 'down':
                        endY += distance;
                        break;
                    case 'left':
                        endX -= distance;
                        break;
                    case 'right':
                        endX += distance;
                        break;
                }
                
                const response = await fetch(`http://localhost:${this.wdaPort}/session/${this.wdaSession}/actions`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        actions: [{
                            type: 'pointer',
                            id: 'finger1',
                            parameters: { pointerType: 'touch' },
                            actions: [
                                { type: 'pointerMove', duration: 0, x: startX, y: startY },
                                { type: 'pointerDown', button: 0 },
                                { type: 'pointerMove', duration: 800, x: endX, y: endY },
                                { type: 'pointerUp', button: 0 }
                            ]
                        }]
                    })
                });
                
                if (response.ok) {
                    console.log(`✅ Swiped ${direction} from (${startX}, ${startY})`);
                    return true;
                }
            } catch (error) {
                console.warn(`Failed to swipe: ${error.message}`);
            }
        }
        return false;
    }

    /**
     * Wait for element to appear
     */
    async waitForElement(selector, timeout = 10000) {
        const startTime = Date.now();
        
        while (Date.now() - startTime < timeout) {
            const elements = await this.getAccessibilityTree();
            const element = elements.find(el => 
                el.label.includes(selector) ||
                el.name.includes(selector) ||
                el.identifier.includes(selector)
            );
            
            if (element) {
                console.log(`✅ Element found: ${element.label || element.name}`);
                return element;
            }
            
            await new Promise(resolve => setTimeout(resolve, 500));
        }
        
        console.warn(`❌ Element not found within timeout: ${selector}`);
        return null;
    }

    /**
     * Validate UI state
     */
    async validateUIState(expectedElements) {
        const elements = await this.getAccessibilityTree();
        const results = [];
        
        for (const expected of expectedElements) {
            const found = elements.find(el => 
                el.label.includes(expected.text || '') ||
                el.name.includes(expected.text || '') ||
                el.type === expected.type
            );
            
            results.push({
                expected,
                found: !!found,
                element: found,
                message: found ? `✅ Found: ${expected.text || expected.type}` : `❌ Missing: ${expected.text || expected.type}`
            });
        }
        
        return results;
    }

    /**
     * Automated UI testing workflow
     */
    async runUITest(testSteps) {
        console.log('🧪 Starting automated UI test...');
        const results = [];
        
        for (let i = 0; i < testSteps.length; i++) {
            const step = testSteps[i];
            console.log(`Step ${i + 1}: ${step.description}`);
            
            try {
                let result;
                switch (step.action) {
                    case 'tap':
                        result = await this.tapElement(step.selector);
                        break;
                    case 'enter':
                        result = await this.enterText(step.text);
                        break;
                    case 'wait':
                        result = await this.waitForElement(step.selector, step.timeout);
                        break;
                    case 'validate':
                        result = await this.validateUIState(step.expectedElements);
                        break;
                    case 'swipe':
                        result = await this.swipeGesture(step.direction, step.x, step.y, step.distance);
                        break;
                    case 'screenshot':
                        const screenshotPath = await this.takeScreenshot();
                        result = { screenshot: screenshotPath };
                        break;
                }
                
                results.push({ step: i + 1, success: true, result, description: step.description });
                
                if (step.waitAfter) {
                    await new Promise(resolve => setTimeout(resolve, step.waitAfter));
                }
            } catch (error) {
                console.error(`❌ Step ${i + 1} failed: ${error.message}`);
                results.push({ step: i + 1, success: false, error: error.message, description: step.description });
                
                if (step.continueOnError !== true) {
                    break;
                }
            }
        }
        
        console.log('🧪 UI test completed');
        return results;
    }

    /**
     * Fallback: Get elements from screenshot analysis
     */
    async getElementsFromScreenshot() {
        console.log('📷 Using screenshot-based element detection...');
        // This is a placeholder for screenshot-based element detection
        // In a full implementation, this would use computer vision to detect UI elements
        const screenshot = await this.takeScreenshot();
        
        // Basic implementation: return empty array
        // TODO: Implement OCR or ML-based element detection
        return [];
    }

    /**
     * Clean up WebDriverAgent session
     */
    async cleanupWDA() {
        if (this.wdaSession) {
            try {
                await fetch(`http://localhost:${this.wdaPort}/session/${this.wdaSession}`, {
                    method: 'DELETE'
                });
                console.log('✅ WebDriverAgent session cleaned up');
            } catch (error) {
                console.warn(`Failed to cleanup WDA session: ${error.message}`);
            }
            this.wdaSession = null;
        }
    }

    /**
     * Full automation flow
     */
    async runFullFlow(options = {}) {
        const {
            deviceName = null,
            screenshot = false,
            monitoring = true,
            build = true
        } = options;
        
        try {
            console.log('🚀 Starting iOS Simulator automation...\n');
            
            // 1. Boot simulator
            await this.bootSimulator(deviceName);
            
            // 2. Build app if requested
            if (build) {
                await this.buildApp();
            }
            
            // 3. Install and launch
            await this.installAndLaunchApp();
            
            // 4. Start monitoring if requested
            if (monitoring) {
                await this.startLogMonitoring();
            }
            
            // 5. Wait a bit for app to fully launch
            await new Promise(resolve => setTimeout(resolve, 3000));
            
            // 6. Take screenshot if requested
            if (screenshot) {
                await this.takeScreenshot();
            }
            
            // 7. Initialize advanced UI control
            if (options.enableWDA !== false) {
                await this.initializeWDA();
            }
            
            // 8. Get final state with accessibility info
            const state = await this.getAppState();
            const elements = await this.getAccessibilityTree();
            
            console.log('\n✅ Automation complete!');
            console.log('📊 App State:', state);
            console.log(`📱 Found ${elements.length} interactive elements`);
            
            return { ...state, elements, wdaEnabled: !!this.wdaSession };
        } catch (error) {
            console.error(`❌ Automation failed: ${error.message}`);
            throw error;
        }
    }

    // ================================================================
    // ENHANCED UI AUTOMATION METHODS (Platform Parity with Android)
    // ================================================================

    /**
     * Automated test: Lost Lake Oregon flow (iOS version)
     */
    async testLostLakeOregonFlow() {
        try {
            console.log('🧪 Starting Lost Lake Oregon automated test (iOS)...');
            
            // Step 1: Ensure app is running and on main screen
            await this.ensureAppRunning();
            const startScreenshot = await this.takeScreenshot('ios-test-start.png');
            
            // Step 2: Find and tap destination input field
            console.log('🎯 Step 1: Finding destination input field...');
            const inputElement = await this.waitForElement('Where would you like to go?', 10000);
            
            if (inputElement) {
                await this.tapElement('Where would you like to go?');
                console.log('✅ Tapped destination input field');
            } else {
                throw new Error('Destination input field not found');
            }
            
            // Wait for keyboard to appear
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            // Step 3: Type "Lost Lake, Oregon"
            console.log('⌨️ Step 2: Typing "Lost Lake, Oregon"...');
            await this.typeText('Lost Lake, Oregon');
            
            const textEnteredScreenshot = await this.takeScreenshot('ios-text-entered.png');
            
            // Step 4: Tap the Go button
            console.log('🚀 Step 3: Tapping Go button...');
            try {
                // Try to find Go button by different criteria
                const goElement = await this.waitForElement('Navigate', 5000);
                if (goElement) {
                    await this.tapElement('Navigate');
                } else {
                    // Try alternative selectors
                    await this.tapElement('Go');
                }
            } catch (error) {
                console.log('Trying coordinate-based Go button tap...');
                // Use approximate coordinates for Go button (adjust based on your UI)
                await this.tapCoordinates(350, 300);
            }
            
            // Step 5: Wait for POI screen transition
            console.log('⏳ Step 4: Waiting for POI screen...');
            await new Promise(resolve => setTimeout(resolve, 3000));
            
            const poiScreenshot = await this.takeScreenshot('ios-poi-screen.png');
            
            // Step 6: Validate POI information is displayed
            console.log('✅ Step 5: Validating POI information...');
            const elements = await this.getAccessibilityTree();
            
            // Look for Lost Lake related information
            const poiElements = elements.filter(el => {
                const text = (el.label || el.name || '').toLowerCase();
                return text.includes('lost lake') || 
                       text.includes('oregon') || 
                       text.includes('destination') || 
                       text.includes('poi') ||
                       text.includes('trip');
            });
            
            if (poiElements.length > 0) {
                console.log('✅ POI information found on screen:');
                poiElements.forEach(el => {
                    console.log(`  - ${el.label || el.name} (${el.type})`);
                });
                
                return {
                    success: true,
                    platform: 'iOS',
                    message: 'Lost Lake Oregon flow completed successfully',
                    poiElements: poiElements.length,
                    elementsFound: poiElements,
                    screenshots: [
                        'ios-test-start.png',
                        'ios-text-entered.png', 
                        'ios-poi-screen.png'
                    ]
                };
            } else {
                console.warn('⚠️ No Lost Lake POI information found on screen');
                return {
                    success: false,
                    platform: 'iOS',
                    message: 'POI information not found',
                    totalElements: elements.length,
                    elements: elements.map(el => ({ 
                        type: el.type, 
                        label: el.label, 
                        name: el.name 
                    }))
                };
            }
            
        } catch (error) {
            await this.takeScreenshot('ios-test-error.png');
            throw new Error(`Lost Lake Oregon test failed (iOS): ${error.message}`);
        }
    }

    /**
     * Type text using iOS text input
     */
    async typeText(text) {
        if (!this.wdaSession) {
            await this.initializeWDA();
        }

        if (this.wdaSession) {
            try {
                // Use WebDriverAgent to type text
                const response = await fetch(`http://localhost:${this.wdaPort}/session/${this.wdaSession.sessionId}/wda/keys`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ value: [text] })
                });
                
                if (response.ok) {
                    console.log(`✅ Typed text: "${text}"`);
                    return true;
                }
            } catch (error) {
                console.warn(`WebDriverAgent text input failed: ${error.message}`);
            }
        }
        
        // Fallback to simctl text input
        try {
            await execAsync(`xcrun simctl io ${this.activeSimulator.udid} text "${text}"`);
            console.log(`✅ Typed text (simctl): "${text}"`);
            return true;
        } catch (error) {
            throw new Error(`Failed to type text: ${error.message}`);
        }
    }

    /**
     * Enhanced wait for element with better iOS support
     */
    async waitForElementEnhanced(criteria, timeout = 10000) {
        const startTime = Date.now();
        
        while (Date.now() - startTime < timeout) {
            try {
                const elements = await this.getAccessibilityTree();
                const element = elements.find(el => {
                    if (typeof criteria === 'string') {
                        return (el.label && el.label.includes(criteria)) ||
                               (el.name && el.name.includes(criteria));
                    } else if (typeof criteria === 'object') {
                        if (criteria.text && el.label && el.label.includes(criteria.text)) return true;
                        if (criteria.type && el.type === criteria.type) return true;
                        if (criteria.label && el.label && el.label.includes(criteria.label)) return true;
                    }
                    return false;
                });
                
                if (element) {
                    console.log(`✅ Element found: ${JSON.stringify(criteria)}`);
                    return element;
                }
            } catch (error) {
                // Continue waiting
            }
            
            await new Promise(resolve => setTimeout(resolve, 500));
        }
        
        throw new Error(`Element not found within ${timeout}ms: ${JSON.stringify(criteria)}`);
    }

    /**
     * Ensure app is running on the correct screen (iOS version)
     */
    async ensureAppRunning() {
        try {
            // Check if app is running by looking for key elements
            const elements = await this.getAccessibilityTree();
            const hasDestinationInput = elements.some(el => 
                (el.label && el.label.includes('Where would you like to go?')) ||
                (el.name && el.name.includes('Where would you like to go?'))
            );
            
            if (!hasDestinationInput) {
                console.log('📱 App not on destination screen, launching...');
                await this.installAndLaunchApp();
                await new Promise(resolve => setTimeout(resolve, 3000));
            } else {
                console.log('✅ App is on Set Destination screen');
            }
        } catch (error) {
            console.log('📱 App not running, launching...');
            await this.installAndLaunchApp();
            await new Promise(resolve => setTimeout(resolve, 3000));
        }
    }

    /**
     * Validate button visibility and states (iOS version)
     */
    async validateButtonsIOS() {
        try {
            console.log('🔘 Validating button visibility and states (iOS)...');
            
            const elements = await this.getAccessibilityTree();
            await this.takeScreenshot('ios-button-validation.png');
            
            // Find buttons and interactive elements
            const buttons = elements.filter(el => 
                el.type === 'Button' || 
                el.type === 'IconButton' ||
                (el.label && (el.label.includes('Navigate') || el.label.includes('Mic')))
            );
            
            console.log(`Found ${buttons.length} interactive elements:`);
            
            const results = {
                goButton: null,
                micButton: null,
                otherButtons: []
            };
            
            buttons.forEach(button => {
                const description = `${button.label || button.name || 'No label'} (${button.type})`;
                console.log(`  - ${description} at (${button.rect?.x || 0}, ${button.rect?.y || 0})`);
                
                // Classify buttons
                const buttonText = (button.label || button.name || '').toLowerCase();
                if (buttonText.includes('navigate') || buttonText.includes('go')) {
                    results.goButton = button;
                } else if (buttonText.includes('mic') || buttonText.includes('microphone')) {
                    results.micButton = button;
                } else {
                    results.otherButtons.push(button);
                }
            });
            
            return {
                success: true,
                platform: 'iOS',
                buttonCount: buttons.length,
                results: results,
                screenshot: 'ios-button-validation.png'
            };
            
        } catch (error) {
            throw new Error(`iOS button validation failed: ${error.message}`);
        }
    }
}

// CLI Interface
async function main() {
    const args = process.argv.slice(2);
    const command = args[0] || 'run';
    
    const manager = new IOSSimulatorManager();
    
    try {
        switch (command) {
            case 'run':
            case 'launch':
                await manager.runFullFlow({
                    deviceName: args[1],
                    screenshot: args.includes('--screenshot'),
                    monitoring: !args.includes('--no-logs'),
                    build: !args.includes('--no-build')
                });
                break;
                
            case 'list':
                const simulators = await manager.listSimulators();
                console.log('📱 Available Simulators:');
                simulators.forEach(sim => {
                    const status = sim.state === 'Booted' ? '🟢' : '⚪';
                    console.log(`${status} ${sim.name} (${sim.runtime}) - ${sim.udid}`);
                });
                break;
                
            case 'screenshot':
                await manager.bootSimulator();
                const screenshotPath = await manager.takeScreenshot(args[1]);
                console.log(`Screenshot saved: ${screenshotPath}`);
                break;
                
            case 'logs':
                await manager.bootSimulator();
                await manager.startLogMonitoring(args[1] || 'Roadtrip-Copilot');
                // Keep process alive
                process.stdin.resume();
                break;
                
            case 'test-model':
                // Test model specifically
                console.log('🧪 Testing Gemma-3N Model Integration...\n');
                await manager.bootSimulator();
                await manager.buildApp();
                
                // Install and launch app
                const appPath = path.join(manager.iosPath, 'build/Build/Products/Debug-iphonesimulator/RoadtripCopilot.app');
                
                // Verify app exists
                try {
                    await fs.access(appPath);
                } catch {
                    throw new Error(`App not found at: ${appPath}. Build may have failed.`);
                }
                
                // Install the app
                console.log('📦 Installing app...');
                await execAsync(`xcrun simctl install booted "${appPath}"`);
                console.log('✅ App installed');
                
                // Clear previous logs
                await execAsync('xcrun simctl spawn booted log clear').catch(() => {});
                
                // Launch app
                console.log('🚀 Launching app...');
                const { stdout: launchOut } = await execAsync('xcrun simctl launch booted com.hmi2.roadtrip-copilot');
                const pid = launchOut.split(':')[1]?.trim() || 'unknown';
                console.log(`✅ App launched (PID: ${pid})`);
                
                // Wait for model to load and test to run
                console.log('⏳ Waiting for model initialization...');
                await new Promise(resolve => setTimeout(resolve, 5000));
                
                // Get recent logs
                console.log('\n📋 Checking for model test results...\n');
                await manager.getRecentLogs('RoadtripCopilot', 20);
                
                // Also try to monitor live logs
                console.log('\n📡 Starting live log monitoring...\n');
                await manager.startLogMonitoring('RoadtripCopilot');
                
                // Wait a bit more for any additional output
                await new Promise(resolve => setTimeout(resolve, 5000));
                
                manager.stopLogMonitoring();
                console.log('\n✅ Model test complete');
                break;
                
            case 'validate':
                await manager.bootSimulator();
                const validation = await manager.validateAppLaunch();
                
                if (validation.success) {
                    console.log('🎉 App validation PASSED - No crashes detected');
                    process.exit(0);
                } else {
                    console.error(`❌ App validation FAILED: ${validation.error}`);
                    if (validation.crashes.length > 0) {
                        console.error('Crashes detected:');
                        validation.crashes.forEach(crash => {
                            console.error(`  - ${crash.timestamp}: ${crash.reason}`);
                        });
                    }
                    process.exit(1);
                }
                break;
                
            case 'reset':
                await manager.bootSimulator();
                await manager.resetSimulator();
                break;
                
            case 'state':
                await manager.bootSimulator();
                const state = await manager.getAppState();
                console.log('App State:', JSON.stringify(state, null, 2));
                break;
                
            case 'elements':
                await manager.bootSimulator();
                await manager.initializeWDA();
                const elements = await manager.getAccessibilityTree();
                console.log(`Found ${elements.length} elements:`);
                elements.forEach((el, i) => {
                    console.log(`${i + 1}. ${el.type} - "${el.label || el.name}" at (${el.rect.x}, ${el.rect.y})`);
                });
                break;
                
            case 'tap':
                await manager.bootSimulator();
                if (args[1] && args[2]) {
                    await manager.tapCoordinates(parseInt(args[1]), parseInt(args[2]));
                } else if (args[1]) {
                    await manager.tapElement(args[1]);
                } else {
                    console.error('Usage: tap <x> <y> OR tap <element_selector>');
                }
                break;
                
            case 'type':
                await manager.bootSimulator();
                if (args[1]) {
                    await manager.enterText(args[1]);
                } else {
                    console.error('Usage: type <text>');
                }
                break;
                
            case 'swipe':
                await manager.bootSimulator();
                if (args[1] && args[2] && args[3]) {
                    await manager.swipeGesture(args[1], parseInt(args[2]), parseInt(args[3]), parseInt(args[4]) || 200);
                } else {
                    console.error('Usage: swipe <direction> <startX> <startY> [distance]');
                }
                break;
                
            case 'lost-lake-test':
                console.log('🧪 Running Lost Lake Oregon automated test (iOS)...');
                await manager.bootSimulator();
                await manager.initializeWDA();
                const testResult = await manager.testLostLakeOregonFlow();
                console.log('\n📊 iOS Test Results:');
                console.log(JSON.stringify(testResult, null, 2));
                break;
                
            case 'validate-buttons':
                console.log('🔘 Validating button states (iOS)...');
                await manager.bootSimulator();
                await manager.initializeWDA();
                const buttonResult = await manager.validateButtonsIOS();
                console.log('\n📊 iOS Button Validation Results:');
                console.log(JSON.stringify(buttonResult, null, 2));
                break;
                
            case 'test':
                await manager.bootSimulator();
                // Example UI test
                const testSteps = [
                    { action: 'screenshot', description: 'Take initial screenshot' },
                    { action: 'wait', selector: 'Allow', timeout: 5000, description: 'Wait for location permission' },
                    { action: 'tap', selector: 'Allow', description: 'Grant location permission', waitAfter: 1000 },
                    { action: 'validate', expectedElements: [{ type: 'Button', text: 'Get Started' }], description: 'Verify app loaded' },
                    { action: 'screenshot', description: 'Take final screenshot' }
                ];
                
                const results = await manager.runUITest(testSteps);
                console.log('Test Results:', JSON.stringify(results, null, 2));
                break;
                
            case 'help':
            default:
                console.log(`
iOS Simulator Manager - Advanced MCP Tool for iOS app automation and testing

Usage: node ios-simulator-manager.js [command] [options]

Commands:
  run/launch [device]     Build, install and launch app (default)
    --screenshot         Take a screenshot after launch
    --no-logs           Don't monitor logs
    --no-build          Skip building (use existing build)
    --enable-wda        Enable WebDriverAgent for advanced UI control
    
  list                   List available simulators
  screenshot [path]      Take a screenshot
  logs [filter]          Monitor simulator logs
  validate               Build, launch app and validate no crashes occur
  reset                  Reset simulator to clean state
  state                  Get current app state
  
  Advanced UI Control:
  elements               List all interactive elements on screen
  tap <x> <y>           Tap at coordinates
  tap <selector>        Tap element by label/name/identifier
  type <text>           Enter text into focused field
  swipe <dir> <x> <y>   Swipe from coordinates (up/down/left/right)
  test                  Run automated UI test workflow
  
  Automated Test Flows:
  lost-lake-test        🧪 Run complete Lost Lake Oregon automated flow test (iOS)
  validate-buttons      🔘 Validate button visibility and accessibility (iOS)
  
  help                   Show this help message

Examples:
  # Basic automation
  node ios-simulator-manager.js run "iPhone 16" --enable-wda
  node ios-simulator-manager.js run --screenshot --no-build
  
  # UI interaction
  node ios-simulator-manager.js elements
  node ios-simulator-manager.js tap "Allow"
  node ios-simulator-manager.js tap 200 300
  node ios-simulator-manager.js type "Hello World"
  node ios-simulator-manager.js swipe up 200 400
  
  # Testing and validation
  node ios-simulator-manager.js test
  node ios-simulator-manager.js logs "Speech"
  node ios-simulator-manager.js screenshot ~/Desktop/app.png
  
  # Automated Test Flows (Platform Parity)
  node ios-simulator-manager.js lost-lake-test     # Run complete Lost Lake Oregon flow (iOS)
  node ios-simulator-manager.js validate-buttons   # Check button states and accessibility (iOS)
                `);
                break;
        }
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
}

// Handle cleanup
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down...');
    const manager = new IOSSimulatorManager();
    manager.stopLogMonitoring();
    process.exit(0);
});

if (require.main === module) {
    main();
}

module.exports = IOSSimulatorManager;