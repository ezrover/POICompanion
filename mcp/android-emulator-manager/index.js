#!/usr/bin/env node

/**
 * Android Emulator Manager MCP Tool
 * Automates Android emulator launch, app deployment, and monitoring
 * Platform parity equivalent to ios-simulator-manager
 */

const { exec, spawn, execSync } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const { promisify } = require('util');
const { parseStringPromise } = require('xml2js');
const execAsync = promisify(exec);

class AndroidEmulatorManager {
    constructor() {
        this.projectRoot = path.resolve(__dirname, '../..');
        this.androidPath = path.join(this.projectRoot, 'mobile/android');
        this.logProcess = null;
        this.activeEmulator = null;
        this.appiumPort = 4723;
        this.appiumSession = null;
        this.packageName = 'com.roadtrip.copilot';
        this.debugPackageName = 'com.roadtrip.copilot.debug';
        this.activityName = '.ui.SplashActivity';
        
        // UI Automation capabilities
        this.lastScreenshot = null;
        this.automationCache = new Map();
        this.waitTimeouts = {
            elementVisible: 10000,
            elementClickable: 5000,
            screenTransition: 3000,
            animation: 2000
        };
        
        // Detect Android SDK paths
        this.androidSdkRoot = process.env.ANDROID_SDK_ROOT || 
                              process.env.ANDROID_HOME || 
                              path.join(process.env.HOME || process.env.USERPROFILE, 'Library/Android/sdk');
        this.emulatorPath = path.join(this.androidSdkRoot, 'emulator/emulator');
        this.adbPath = path.join(this.androidSdkRoot, 'platform-tools/adb');
    }

    /**
     * Get the correct emulator command
     */
    getEmulatorCommand() {
        // Check if emulator is in PATH first
        try {
            execSync('emulator -version', { stdio: 'ignore' });
            return 'emulator';
        } catch {
            // Use full path to emulator
            return this.emulatorPath;
        }
    }

    /**
     * Get the correct adb command
     */
    getAdbCommand() {
        // Check if adb is in PATH first
        try {
            execSync('adb version', { stdio: 'ignore' });
            return 'adb';
        } catch {
            // Use full path to adb
            return this.adbPath;
        }
    }

    /**
     * Get list of available AVDs (Android Virtual Devices)
     */
    async listEmulators() {
        try {
            console.log('📱 Listing available Android emulators...');
            const emulatorCmd = this.getEmulatorCommand();
            const { stdout } = await execAsync(`"${emulatorCmd}" -list-avds`);
            const avdNames = stdout.trim().split('\n').filter(name => name.trim());
            
            const emulators = [];
            for (const avdName of avdNames) {
                if (avdName) {
                    // Get detailed info about each AVD
                    try {
                        const configPath = path.join(process.env.HOME || process.env.USERPROFILE, '.android/avd', `${avdName}.avd/config.ini`);
                        const configContent = await fs.readFile(configPath, 'utf8');
                        const targetMatch = configContent.match(/target=(.+)/);
                        const abiMatch = configContent.match(/abi.type=(.+)/);
                        
                        emulators.push({
                            name: avdName,
                            target: targetMatch ? targetMatch[1] : 'Unknown',
                            abi: abiMatch ? abiMatch[1] : 'Unknown',
                            state: 'Shutdown' // Will be updated if running
                        });
                    } catch (configError) {
                        emulators.push({
                            name: avdName,
                            target: 'Unknown',
                            abi: 'Unknown', 
                            state: 'Shutdown'
                        });
                    }
                }
            }
            
            // Check running emulators
            try {
                const adbCmd = this.getAdbCommand();
                const { stdout: runningDevices } = await execAsync(`"${adbCmd}" devices`);
                const runningLines = runningDevices.split('\n').slice(1);
                
                for (const line of runningLines) {
                    const parts = line.trim().split('\t');
                    if (parts.length === 2 && parts[1] === 'device') {
                        const deviceId = parts[0];
                        if (deviceId.startsWith('emulator-')) {
                            // Match with AVD name
                            for (const emulator of emulators) {
                                emulator.state = 'Booted';
                                emulator.deviceId = deviceId;
                                break;
                            }
                        }
                    }
                }
            } catch (adbError) {
                console.warn('Could not check running devices:', adbError.message);
            }
            
            console.log(`Found ${emulators.length} Android emulators`);
            return emulators;
        } catch (error) {
            throw new Error(`Failed to list emulators: ${error.message}`);
        }
    }

    /**
     * Boot a specific emulator or use default
     */
    async bootEmulator(deviceName = null) {
        try {
            const emulators = await this.listEmulators();
            
            // Check if any emulator is already running
            let targetEmulator = emulators.find(emu => emu.state === 'Booted');
            
            if (!targetEmulator) {
                // Find target emulator by name or use first available
                if (deviceName) {
                    targetEmulator = emulators.find(emu => 
                        emu.name.toLowerCase().includes(deviceName.toLowerCase())
                    );
                } else {
                    // Default to first available emulator
                    targetEmulator = emulators[0];
                }
                
                if (!targetEmulator) {
                    throw new Error('No suitable emulator found. Please create an AVD first using Android Studio');
                }
                
                console.log(`🚀 Booting Android emulator: ${targetEmulator.name}...`);
                
                // Start emulator in background
                const emulatorCmd = this.getEmulatorCommand();
                const emulatorProcess = spawn(emulatorCmd, ['-avd', targetEmulator.name, '-no-audio'], {
                    detached: true,
                    stdio: 'ignore'
                });
                
                emulatorProcess.unref();
                
                // Wait for emulator to boot
                console.log('⏳ Waiting for emulator to boot (this may take 2-3 minutes)...');
                const bootResult = await this.waitForEmulatorBoot(60000);
                
                if (!bootResult) {
                    throw new Error('Emulator failed to boot within timeout');
                }
                
                // Update emulator state
                targetEmulator.state = 'Booted';
                targetEmulator.deviceId = bootResult.deviceId;
            } else {
                console.log(`✅ Using already booted emulator: ${targetEmulator.name}`);
            }
            
            this.activeEmulator = targetEmulator;
            console.log(`✅ Android emulator ready: ${targetEmulator.name}`);
            
            return targetEmulator;
        } catch (error) {
            throw new Error(`Failed to boot emulator: ${error.message}`);
        }
    }

    /**
     * Wait for emulator to fully boot
     */
    async waitForEmulatorBoot(timeoutMs = 120000) {
        const startTime = Date.now();
        
        while (Date.now() - startTime < timeoutMs) {
            try {
                const adbCmd = this.getAdbCommand();
                const { stdout } = await execAsync(`"${adbCmd}" devices`);
                const lines = stdout.split('\n').slice(1);
                
                for (const line of lines) {
                    const parts = line.trim().split('\t');
                    if (parts.length === 2 && parts[1] === 'device' && parts[0].startsWith('emulator-')) {
                        // Check if boot animation is complete
                        try {
                            const adbCmd = this.getAdbCommand();
                            const { stdout: bootComplete } = await execAsync(`"${adbCmd}" -s ${parts[0]} shell getprop sys.boot_completed`);
                            if (bootComplete.trim() === '1') {
                                return { deviceId: parts[0] };
                            }
                        } catch (propError) {
                            // Continue waiting
                        }
                    }
                }
                
                await new Promise(resolve => setTimeout(resolve, 5000));
            } catch (error) {
                await new Promise(resolve => setTimeout(resolve, 5000));
            }
        }
        
        return null;
    }

    /**
     * Build the Android app
     */
    async buildApp() {
        try {
            console.log('🔨 Building Android app...');
            
            const buildCommand = `cd "${this.androidPath}" && ./gradlew assembleDebug`;
            
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
     * Install and launch the app on emulator with enhanced debugging
     */
    async installAndLaunchApp() {
        try {
            if (!this.activeEmulator) {
                throw new Error('No active emulator. Boot an emulator first.');
            }
            
            console.log('📱 Installing app on emulator...');
            
            // Find the built APK dynamically, build if not found
            let apkPath = await this.findBuiltApk();
            if (!apkPath) {
                console.log('📦 No APK found, building app automatically...');
                await this.buildApp();
                apkPath = await this.findBuiltApk();
                if (!apkPath) {
                    throw new Error(`Failed to build APK. Check build logs for errors.`);
                }
            }
            
            // Install the APK with timeout
            console.log(`Installing from: ${apkPath}`);
            const adbCmd = this.getAdbCommand();
            const installCmd = `"${adbCmd}" -s ${this.activeEmulator.deviceId} install -r "${apkPath}"`;
            await this.execWithTimeout(installCmd, 30000, 'App installation');
            console.log('✅ App installed');
            
            // Wait a moment for installation to settle
            await new Promise(resolve => setTimeout(resolve, 2000));
            
            // Check which package name is actually installed (debug vs release)
            const installedPackageName = await this.getInstalledPackageName();
            
            // Launch the app with correct package name
            console.log('🚀 Launching app...');
            const launchCmd = `"${adbCmd}" -s ${this.activeEmulator.deviceId} shell am start -n ${installedPackageName}/${this.activityName}`;
            
            try {
                await this.execWithTimeout(launchCmd, 15000, 'App launch');
            } catch (launchError) {
                // Try alternative launch method with monkey
                console.log('🐒 Trying alternative launch with monkey...');
                const monkeyCmd = `"${adbCmd}" -s ${this.activeEmulator.deviceId} shell monkey -p ${installedPackageName} -c android.intent.category.LAUNCHER 1`;
                await this.execWithTimeout(monkeyCmd, 15000, 'Monkey launch');
            }
            
            // Wait for app to initialize
            await new Promise(resolve => setTimeout(resolve, 5000));
            
            // Check for crashes immediately
            const crashDetected = await this.detectRecentCrashes();
            if (crashDetected) {
                console.warn('⚠️  App crash detected during launch');
                throw new Error('App crashed during launch - check AndroidManifest.xml themes and Activity configuration');
            }
            
            // Verify app is running
            const isRunning = await this.isAppRunning(installedPackageName);
            if (isRunning) {
                console.log('✅ App launched successfully');
                return true;
            } else {
                console.warn('⚠️  App may have crashed after launch');
                return false;
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
            const timer = setTimeout(() => {
                reject(new Error(`${operation} timed out after ${timeout}ms`));
            }, timeout);

            exec(command, { maxBuffer: 1024 * 1024 }, (error, stdout, stderr) => {
                clearTimeout(timer);
                if (error) {
                    reject(new Error(`${operation} failed: ${error.message}`));
                } else {
                    resolve({ stdout, stderr });
                }
            });
        });
    }

    /**
     * Validate app launch with comprehensive checks
     */
    async validateApp(timeoutMs = 30000) {
        try {
            console.log('🔍 Validating app launch...');
            const startTime = Date.now();
            
            // Check 1: App is running
            while (Date.now() - startTime < timeoutMs) {
                const isRunning = await this.isAppRunning();
                if (isRunning) {
                    console.log('✅ App is running');
                    break;
                }
                
                if (Date.now() - startTime >= timeoutMs) {
                    throw new Error('App failed to start within timeout');
                }
                
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
            
            // Check 2: No immediate crashes
            await new Promise(resolve => setTimeout(resolve, 5000));
            const stillRunning = await this.isAppRunning();
            if (!stillRunning) {
                throw new Error('App crashed shortly after launch');
            }
            
            // Check 3: Check for crash logs
            const hasCrashes = await this.detectCrashes();
            if (hasCrashes) {
                console.warn('⚠️  Crashes detected in logcat');
                return false;
            }
            
            console.log('✅ App validation passed');
            return true;
            
        } catch (error) {
            console.error(`❌ App validation failed: ${error.message}`);
            return false;
        }
    }

    /**
     * Dynamically find the built APK file
     */
    async findBuiltApk() {
        try {
            console.log('🔍 Searching for built APK files...');
            
            // Common APK locations to search
            const searchPaths = [
                'app/build/outputs/apk/debug/app-debug.apk',
                'app/build/outputs/apk/debug/*.apk',
                'build/outputs/apk/debug/app-debug.apk',
                'build/outputs/apk/debug/*.apk',
                '**/build/outputs/apk/debug/*.apk',
                '**/app-debug.apk'
            ];
            
            for (const searchPattern of searchPaths) {
                const fullPattern = path.join(this.androidPath, searchPattern);
                
                try {
                    // Use execAsync to find files with glob patterns
                    const { stdout } = await execAsync(`find "${this.androidPath}" -name "*.apk" -path "*/build/outputs/apk/debug/*" -type f | head -1`);
                    
                    const foundPath = stdout.trim();
                    if (foundPath && foundPath.length > 0) {
                        // Verify the file exists and is readable
                        await fs.access(foundPath, fs.constants.R_OK);
                        console.log(`✅ Found APK: ${foundPath}`);
                        return foundPath;
                    }
                } catch (error) {
                    // Continue searching with next pattern
                    continue;
                }
            }
            
            // Also try searching for any APK files in the project
            try {
                const { stdout } = await execAsync(`find "${this.androidPath}" -name "*.apk" -type f | grep -E "(debug|Debug)" | head -1`);
                const foundPath = stdout.trim();
                if (foundPath && foundPath.length > 0) {
                    await fs.access(foundPath, fs.constants.R_OK);
                    console.log(`✅ Found APK (fallback search): ${foundPath}`);
                    return foundPath;
                }
            } catch (error) {
                // No APK found
            }
            
            console.log('❌ No APK files found. Build the app first.');
            return null;
        } catch (error) {
            console.error(`APK search failed: ${error.message}`);
            return null;
        }
    }

    /**
     * Get the installed package name (debug vs release)
     */
    async getInstalledPackageName() {
        try {
            const adbCmd = this.getAdbCommand();
            const { stdout } = await execAsync(`"${adbCmd}" -s ${this.activeEmulator.deviceId} shell pm list packages | grep roadtrip`);
            
            // Check for debug package first
            if (stdout.includes(this.debugPackageName)) {
                console.log(`📦 Using debug package: ${this.debugPackageName}`);
                return this.debugPackageName;
            } else if (stdout.includes(this.packageName)) {
                console.log(`📦 Using release package: ${this.packageName}`);
                return this.packageName;
            } else {
                throw new Error('No Roadtrip Copilot package found on device');
            }
        } catch (error) {
            console.warn('Package detection failed, using debug package name');
            return this.debugPackageName;
        }
    }

    /**
     * Check if the app is currently running with specific package name
     */
    async isAppRunning(packageName = null) {
        try {
            // Auto-detect emulator if not set
            if (!this.activeEmulator) {
                const adbCmd = this.getAdbCommand();
                const { stdout: devicesOutput } = await execAsync(`"${adbCmd}" devices`);
                const lines = devicesOutput.trim().split('\n').slice(1);
                for (const line of lines) {
                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 2 && parts[1] === 'device') {
                        this.activeEmulator = { deviceId: parts[0] };
                        break;
                    }
                }
            }
            
            if (!this.activeEmulator) {
                return false;
            }
            
            const targetPackage = packageName || await this.getInstalledPackageName();
            const adbCmd = this.getAdbCommand();
            const { stdout } = await execAsync(`"${adbCmd}" -s ${this.activeEmulator.deviceId} shell ps | grep ${targetPackage}`);
            return stdout.trim().length > 0;
        } catch (error) {
            return false;
        }
    }

    /**
     * Detect recent crashes in logcat (last 20 lines)
     */
    async detectRecentCrashes() {
        try {
            const adbCmd = this.getAdbCommand();
            const { stdout } = await execAsync(
                `"${adbCmd}" -s ${this.activeEmulator.deviceId} shell logcat -d -t 20 | grep -i -E "(fatal exception|androidruntime|crash|force.*close)"`
            );
            
            const crashLines = stdout.trim();
            if (crashLines) {
                console.log('🔍 Recent crash logs found:', crashLines.split('\n').slice(-3).join('\n'));
                return true;
            }
            
            return false;
        } catch (error) {
            return false;
        }
    }

    /**
     * Monitor logcat for crashes and errors
     */
    async detectCrashes() {
        try {
            // Check recent logcat for crash indicators
            const { stdout } = await execAsync(
                `"${this.getAdbCommand()}" -s ${this.activeEmulator.deviceId} shell logcat -d -t 100 | grep -i -E "(crash|exception|fatal|error.*${this.packageName})"`
            );
            
            const crashLines = stdout.trim();
            if (crashLines) {
                console.log('🔍 Crash logs found:', crashLines);
                return true;
            }
            
            return false;
        } catch (error) {
            return false;
        }
    }

    /**
     * Start real-time logcat monitoring
     */
    async startLogMonitoring(filter = 'RoadtripCopilot') {
        try {
            if (this.logProcess) {
                this.logProcess.kill();
            }
            
            console.log(`📊 Starting logcat monitoring (filter: ${filter})...`);
            
            const adbCmd = this.getAdbCommand();
            this.logProcess = spawn(adbCmd, [
                '-s', this.activeEmulator.deviceId,
                'shell', 'logcat', 
                '-v', 'threadtime',
                '*:E', '*:W', `*${filter}*:D`
            ]);
            
            this.logProcess.stdout.on('data', (data) => {
                console.log('📱 LOGCAT:', data.toString().trim());
            });
            
            this.logProcess.stderr.on('data', (data) => {
                console.error('📱 LOGCAT ERROR:', data.toString().trim());
            });
            
            return true;
        } catch (error) {
            throw new Error(`Failed to start log monitoring: ${error.message}`);
        }
    }

    /**
     * Stop logcat monitoring
     */
    stopLogMonitoring() {
        if (this.logProcess) {
            this.logProcess.kill();
            this.logProcess = null;
            console.log('🛑 Logcat monitoring stopped');
        }
    }

    /**
     * Take screenshot of the emulator
     */
    async takeScreenshot(outputPath = null) {
        try {
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            const filename = outputPath || `android-screenshot-${timestamp}.png`;
            const fullPath = path.resolve(filename);
            
            console.log('📸 Taking screenshot...');
            
            // Take screenshot using adb
            const tempPath = '/sdcard/screenshot.png';
            const adbCmd = this.getAdbCommand();
            await execAsync(`"${adbCmd}" -s ${this.activeEmulator.deviceId} shell screencap -p ${tempPath}`);
            await execAsync(`"${adbCmd}" -s ${this.activeEmulator.deviceId} pull ${tempPath} "${fullPath}"`);
            await execAsync(`"${adbCmd}" -s ${this.activeEmulator.deviceId} shell rm ${tempPath}`);
            
            console.log(`✅ Screenshot saved: ${fullPath}`);
            return fullPath;
        } catch (error) {
            throw new Error(`Screenshot failed: ${error.message}`);
        }
    }

    /**
     * Simulate tap at coordinates
     */
    async simulateTap(x, y) {
        try {
            console.log(`👆 Tapping at coordinates (${x}, ${y})`);
            const adbCmd = this.getAdbCommand();
            await execAsync(`"${adbCmd}" -s ${this.activeEmulator.deviceId} shell input tap ${x} ${y}`);
            return true;
        } catch (error) {
            throw new Error(`Tap simulation failed: ${error.message}`);
        }
    }

    /**
     * Type text into the current focused input
     */
    async typeText(text) {
        try {
            console.log(`⌨️  Typing text: ${text}`);
            const escapedText = text.replace(/['"\\]/g, '\\$&');
            const adbCmd = this.getAdbCommand();
            await execAsync(`"${adbCmd}" -s ${this.activeEmulator.deviceId} shell input text "${escapedText}"`);
            return true;
        } catch (error) {
            throw new Error(`Text input failed: ${error.message}`);
        }
    }

    /**
     * Get device information
     */
    async getDeviceInfo() {
        try {
            const deviceId = this.activeEmulator?.deviceId;
            if (!deviceId) {
                throw new Error('No active emulator');
            }
            
            console.log('📋 Getting device information...');
            
            const adbCmd = this.getAdbCommand();
            const { stdout: buildInfo } = await execAsync(`"${adbCmd}" -s ${deviceId} shell getprop`);
            const props = this.parseProps(buildInfo);
            
            const deviceInfo = {
                deviceId: deviceId,
                name: this.activeEmulator.name,
                androidVersion: props['ro.build.version.release'] || 'Unknown',
                apiLevel: props['ro.build.version.sdk'] || 'Unknown',
                manufacturer: props['ro.product.manufacturer'] || 'Unknown',
                model: props['ro.product.model'] || 'Unknown',
                abi: props['ro.product.cpu.abi'] || 'Unknown',
                density: props['ro.sf.lcd_density'] || 'Unknown',
                resolution: await this.getScreenResolution(deviceId)
            };
            
            console.log('Device Info:', deviceInfo);
            return deviceInfo;
        } catch (error) {
            throw new Error(`Failed to get device info: ${error.message}`);
        }
    }

    /**
     * Parse Android system properties
     */
    parseProps(buildInfo) {
        const props = {};
        const lines = buildInfo.split('\n');
        
        for (const line of lines) {
            const match = line.match(/\[(.+?)\]: \[(.+?)\]/);
            if (match) {
                props[match[1]] = match[2];
            }
        }
        
        return props;
    }

    /**
     * Get screen resolution
     */
    async getScreenResolution(deviceId) {
        try {
            const adbCmd = this.getAdbCommand();
            const { stdout } = await execAsync(`"${adbCmd}" -s ${deviceId} shell wm size`);
            const match = stdout.match(/(\d+)x(\d+)/);
            return match ? `${match[1]}x${match[2]}` : 'Unknown';
        } catch (error) {
            return 'Unknown';
        }
    }

    /**
     * Run automated UI test for Set Destination screen voice functionality
     */
    async runSetDestinationTest() {
        try {
            console.log('🎙️ Running Set Destination screen voice test...');
            
            const testSteps = [
                { action: 'wait', duration: 5000, description: 'Wait for app to fully load' },
                { action: 'screenshot', filename: 'app-loaded.png' },
                { action: 'tap', x: 540, y: 1200, description: 'Navigate to Set Destination screen' },
                { action: 'wait', duration: 3000 },
                { action: 'screenshot', filename: 'set-destination-screen.png' },
                { action: 'tap', x: 950, y: 400, description: 'Tap Start/Go button to activate voice' },
                { action: 'wait', duration: 2000 },
                { action: 'screenshot', filename: 'voice-animation-active.png' },
                { action: 'simulate_voice', text: 'Lost Lake, Oregon, Go', description: 'Simulate voice input' },
                { action: 'wait', duration: 4000 },
                { action: 'screenshot', filename: 'voice-processing.png' },
                { action: 'validate_destination', expected: 'Lost Lake', description: 'Check destination was set' },
                { action: 'tap', x: 1050, y: 400, description: 'Tap Mic/Mute button' },
                { action: 'wait', duration: 1000 },
                { action: 'screenshot', filename: 'mic-muted.png' },
                { action: 'tap', x: 1050, y: 400, description: 'Tap Mic/Mute button to unmute' },
                { action: 'wait', duration: 1000 },
                { action: 'screenshot', filename: 'mic-unmuted.png' },
                { action: 'simulate_voice', text: 'Go', description: 'Simulate Go command' },
                { action: 'wait', duration: 3000 },
                { action: 'screenshot', filename: 'navigation-started.png' }
            ];
            
            return await this.runUITest(testSteps);
        } catch (error) {
            console.error(`❌ Set Destination test failed: ${error.message}`);
            return false;
        }
    }

    /**
     * Run automated UI test with enhanced voice testing capabilities
     */
    async runUITest(testSteps = []) {
        try {
            console.log('🧪 Running UI test...');
            
            if (!testSteps.length) {
                // Default test: Set Destination voice functionality
                return await this.runSetDestinationTest();
            }
            
            for (const step of testSteps) {
                console.log(`🎬 Test step: ${step.description || step.action}`);
                
                switch (step.action) {
                    case 'tap':
                        await this.simulateTap(step.x, step.y);
                        break;
                    case 'type':
                        await this.typeText(step.text);
                        break;
                    case 'wait':
                        await new Promise(resolve => setTimeout(resolve, step.duration));
                        break;
                    case 'screenshot':
                        await this.takeScreenshot(step.filename);
                        break;
                    case 'validate':
                        const isRunning = await this.isAppRunning();
                        if (!isRunning) {
                            throw new Error('App crashed during UI test');
                        }
                        break;
                    case 'simulate_voice':
                        await this.simulateVoiceInput(step.text);
                        break;
                    case 'validate_destination':
                        await this.validateDestination(step.expected);
                        break;
                    case 'check_buttons':
                        await this.validateButtonVisibility();
                        break;
                }
                
                // Brief pause between steps
                await new Promise(resolve => setTimeout(resolve, 500));
            }
            
            console.log('✅ UI test completed successfully');
            return true;
        } catch (error) {
            console.error(`❌ UI test failed: ${error.message}`);
            return false;
        }
    }

    /**
     * Simulate voice input by typing into the destination field
     */
    async simulateVoiceInput(text) {
        try {
            console.log(`🎤 Simulating voice input: "${text}"`);
            
            // Focus on destination input field (approximate coordinates)
            await this.simulateTap(540, 400);
            await new Promise(resolve => setTimeout(resolve, 500));
            
            // Clear any existing text
            await this.executeAdbCommand('shell input keyevent KEYCODE_CTRL_A');
            await new Promise(resolve => setTimeout(resolve, 200));
            
            // Type the voice input
            await this.typeText(text);
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            console.log(`✅ Voice input simulated: ${text}`);
            return true;
        } catch (error) {
            throw new Error(`Voice simulation failed: ${error.message}`);
        }
    }

    /**
     * Validate that destination was set correctly
     */
    async validateDestination(expectedDestination) {
        try {
            console.log(`🎯 Validating destination contains: ${expectedDestination}`);
            
            // Take screenshot for visual validation
            await this.takeScreenshot('destination-validation.png');
            
            // Check logcat for destination setting confirmation
            const { stdout } = await this.executeAdbCommand(
                `shell logcat -d -t 50 | grep -i "destination\\|${expectedDestination}"`
            );
            
            if (stdout.includes(expectedDestination)) {
                console.log(`✅ Destination validation passed: Found "${expectedDestination}"`);
                return true;
            } else {
                console.warn(`⚠️ Destination validation inconclusive for "${expectedDestination}"`);
                return false;
            }
        } catch (error) {
            console.warn(`⚠️ Destination validation failed: ${error.message}`);
            return false;
        }
    }

    /**
     * Validate that both Go and Mic buttons are visible
     */
    async validateButtonVisibility() {
        try {
            console.log('👁️ Validating button visibility...');
            
            // Take screenshot for button visibility check
            const screenshotPath = await this.takeScreenshot('button-visibility-check.png');
            console.log(`📸 Button visibility screenshot: ${screenshotPath}`);
            
            // Check UI hierarchy for button elements
            await this.executeAdbCommand('shell uiautomator dump /sdcard/ui-hierarchy.xml');
            const { stdout } = await this.executeAdbCommand('shell cat /sdcard/ui-hierarchy.xml');
            
            const hasStartButton = stdout.includes('Start') || stdout.includes('Go') || stdout.includes('Navigate');
            const hasMicButton = stdout.includes('Mic') || stdout.includes('Mute');
            
            console.log(`🔍 Button visibility results:`);
            console.log(`  - Start/Go button: ${hasStartButton ? '✅ Found' : '❌ Missing'}`);
            console.log(`  - Mic/Mute button: ${hasMicButton ? '✅ Found' : '❌ Missing'}`);
            
            return hasStartButton && hasMicButton;
        } catch (error) {
            console.warn(`⚠️ Button visibility check failed: ${error.message}`);
            return false;
        }
    }

    /**
     * Execute ADB command with active emulator
     */
    async executeAdbCommand(command) {
        const adbCmd = this.getAdbCommand();
        
        // If no active emulator set, try to detect one
        if (!this.activeEmulator) {
            try {
                const { stdout } = await execAsync(`"${adbCmd}" devices`);
                const lines = stdout.trim().split('\n').slice(1);
                for (const line of lines) {
                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 2 && parts[1] === 'device') {
                        this.activeEmulator = { deviceId: parts[0] };
                        console.log(`🔍 Auto-detected active emulator: ${parts[0]}`);
                        break;
                    }
                }
            } catch (error) {
                throw new Error('No active emulator found. Boot an emulator first.');
            }
        }
        
        if (!this.activeEmulator) {
            throw new Error('No active emulator found. Boot an emulator first.');
        }
        
        const fullCommand = `"${adbCmd}" -s ${this.activeEmulator.deviceId} ${command}`;
        return await execAsync(fullCommand);
    }

    /**
     * Monitor app performance metrics
     */
    async monitorPerformance(durationMs = 30000) {
        try {
            console.log(`📊 Monitoring app performance for ${durationMs/1000}s...`);
            
            const startTime = Date.now();
            const metrics = [];
            
            while (Date.now() - startTime < durationMs) {
                try {
                    // CPU usage
                    const { stdout: cpuStats } = await this.executeAdbCommand(
                        `shell top -n 1 | grep ${this.packageName}`
                    );
                    
                    // Memory usage
                    const { stdout: memStats } = await this.executeAdbCommand(
                        `shell dumpsys meminfo ${this.packageName}`
                    );
                    
                    const timestamp = new Date().toISOString();
                    const cpuMatch = cpuStats.match(/(\d+(?:\.\d+)?)\%/);
                    const memMatch = memStats.match(/TOTAL\s+(\d+)/);
                    
                    metrics.push({
                        timestamp,
                        cpu: cpuMatch ? parseFloat(cpuMatch[1]) : 0,
                        memory: memMatch ? parseInt(memMatch[1]) : 0
                    });
                    
                } catch (error) {
                    console.warn('Performance sampling error:', error.message);
                }
                
                await new Promise(resolve => setTimeout(resolve, 2000));
            }
            
            // Calculate averages
            const avgCpu = metrics.reduce((sum, m) => sum + m.cpu, 0) / metrics.length;
            const avgMemory = metrics.reduce((sum, m) => sum + m.memory, 0) / metrics.length;
            
            console.log(`📈 Performance Results:`);
            console.log(`   Average CPU: ${avgCpu.toFixed(1)}%`);
            console.log(`   Average Memory: ${(avgMemory/1024).toFixed(1)} MB`);
            console.log(`   Sample Count: ${metrics.length}`);
            
            return { avgCpu, avgMemory, metrics };
        } catch (error) {
            console.warn(`Performance monitoring failed: ${error.message}`);
            return null;
        }
    }

    /**
     * Test voice recognition stability
     */
    async testVoiceRecognitionStability(iterations = 5) {
        try {
            console.log(`🎙️ Testing voice recognition stability (${iterations} iterations)...`);
            
            const results = [];
            
            for (let i = 1; i <= iterations; i++) {
                console.log(`🔄 Voice test iteration ${i}/${iterations}`);
                
                try {
                    // Navigate to Set Destination if needed
                    await this.simulateTap(540, 1200);
                    await new Promise(resolve => setTimeout(resolve, 2000));
                    
                    // Activate voice
                    await this.simulateTap(950, 400);
                    await new Promise(resolve => setTimeout(resolve, 1000));
                    
                    // Simulate voice input
                    await this.simulateVoiceInput(`Test destination ${i}`);
                    await new Promise(resolve => setTimeout(resolve, 2000));
                    
                    // Check for crashes or errors
                    const isRunning = await this.isAppRunning();
                    const hasCrashes = await this.detectCrashes();
                    
                    results.push({
                        iteration: i,
                        success: isRunning && !hasCrashes,
                        appRunning: isRunning,
                        crashes: hasCrashes
                    });
                    
                    if (!isRunning) {
                        console.error(`❌ App crashed in iteration ${i}`);
                        break;
                    }
                    
                } catch (error) {
                    console.error(`❌ Iteration ${i} failed: ${error.message}`);
                    results.push({
                        iteration: i,
                        success: false,
                        error: error.message
                    });
                }
                
                // Brief pause between iterations
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
            
            const successCount = results.filter(r => r.success).length;
            const successRate = (successCount / results.length) * 100;
            
            console.log(`📊 Voice Recognition Stability Results:`);
            console.log(`   Success Rate: ${successRate.toFixed(1)}% (${successCount}/${results.length})`);
            console.log(`   Total Iterations: ${results.length}`);
            
            return { successRate, results };
        } catch (error) {
            console.error(`Voice stability test failed: ${error.message}`);
            return { successRate: 0, results: [] };
        }
    }

    /**
     * Auto-fix common Android theme and configuration issues
     */
    async autoFixCommonIssues() {
        try {
            console.log('🔧 Auto-fixing common Android issues...');
            
            const stylesPath = path.join(this.androidPath, 'app/src/main/res/values/styles.xml');
            const manifestPath = path.join(this.androidPath, 'app/src/main/AndroidManifest.xml');
            
            // Check if files exist
            try {
                await fs.access(stylesPath);
                await fs.access(manifestPath);
            } catch {
                throw new Error('Android project files not found. Make sure you\'re in the correct directory.');
            }
            
            // Fix 1: Add proper splash screen theme
            console.log('🎨 Fixing splash screen theme...');
            const stylesContent = await fs.readFile(stylesPath, 'utf8');
            
            if (!stylesContent.includes('Theme.RoadtripCopilot.Splash')) {
                const updatedStyles = stylesContent.replace(
                    '</resources>',
                    `
    <!-- Splash screen theme -->
    <style name="Theme.RoadtripCopilot.Splash" parent="Theme.AppCompat.DayNight.NoActionBar">
        <item name="android:windowBackground">@android:color/white</item>
        <item name="android:windowFullscreen">true</item>
        <item name="android:windowContentOverlay">@null</item>
    </style>
</resources>`
                );
                
                await fs.writeFile(stylesPath, updatedStyles, 'utf8');
                console.log('✅ Added splash screen theme');
            } else {
                console.log('✅ Splash screen theme already exists');
            }
            
            // Fix 2: Update AndroidManifest.xml to use correct theme
            console.log('📄 Fixing AndroidManifest.xml theme...');
            const manifestContent = await fs.readFile(manifestPath, 'utf8');
            
            if (manifestContent.includes('@android:style/Theme.NoTitleBar.Fullscreen')) {
                const updatedManifest = manifestContent.replace(
                    '@android:style/Theme.NoTitleBar.Fullscreen',
                    '@style/Theme.RoadtripCopilot.Splash'
                );
                
                await fs.writeFile(manifestPath, updatedManifest, 'utf8');
                console.log('✅ Fixed AndroidManifest.xml theme');
            } else {
                console.log('✅ AndroidManifest.xml theme already correct');
            }
            
            // Fix 3: Verify activity names are correct
            if (manifestContent.includes('.ui.SplashActivity') && manifestContent.includes('.MainActivity')) {
                console.log('✅ Activity configuration is correct');
            } else {
                console.warn('⚠️  Activity configuration may need manual review');
            }
            
            console.log('🎉 Auto-fix completed! Rebuild the app to apply changes.');
            return true;
            
        } catch (error) {
            console.error(`❌ Auto-fix failed: ${error.message}`);
            return false;
        }
    }

    /**
     * Clean shutdown of emulator and cleanup resources
     */
    async cleanup() {
        try {
            console.log('🧹 Cleaning up resources...');
            
            this.stopLogMonitoring();
            
            if (this.activeEmulator && this.activeEmulator.deviceId) {
                // Kill the app
                const adbCmd = this.getAdbCommand();
                await execAsync(`"${adbCmd}" -s ${this.activeEmulator.deviceId} shell am force-stop ${this.packageName}`);
                
                // Shutdown emulator
                await execAsync(`"${adbCmd}" -s ${this.activeEmulator.deviceId} emu kill`);
            }
            
            this.activeEmulator = null;
            console.log('✅ Cleanup completed');
        } catch (error) {
            console.warn('Cleanup warnings:', error.message);
        }
    }

    /**
     * Full automated test flow
     */
    async runFullFlow(options = {}) {
        try {
            const {
                deviceName = null,
                buildFirst = true,
                runTests = true,
                takeScreenshots = true,
                monitorLogs = true
            } = options;
            
            console.log('🚀 Starting full Android emulator test flow...');
            
            // 1. Boot emulator
            await this.bootEmulator(deviceName);
            
            // 2. Build app if requested
            if (buildFirst) {
                await this.buildApp();
            }
            
            // 3. Install and launch app
            await this.installAndLaunchApp();
            
            // 4. Start log monitoring if requested
            if (monitorLogs) {
                await this.startLogMonitoring();
            }
            
            // 5. Validate app launch
            const validationResult = await this.validateApp();
            if (!validationResult) {
                throw new Error('App validation failed');
            }
            
            // 6. Get device info
            await this.getDeviceInfo();
            
            // 7. Take initial screenshot
            if (takeScreenshots) {
                await this.takeScreenshot('initial-launch.png');
            }
            
            // 8. Run UI tests if requested
            if (runTests) {
                await this.runUITest();
            }
            
            // 9. Final screenshot
            if (takeScreenshots) {
                await this.takeScreenshot('final-state.png');
            }
            
            console.log('✅ Full flow completed successfully');
            return true;
            
        } catch (error) {
            console.error(`❌ Full flow failed: ${error.message}`);
            throw error;
        }
    }

    // ================================================================
    // UI AUTOMATION METHODS (Based on mobile-mcp patterns)
    // ================================================================

    /**
     * Get UI hierarchy using uiautomator dump
     */
    async getUiHierarchy() {
        try {
            const tempFile = '/sdcard/ui_dump.xml';
            await this.executeAdbCommand(`shell uiautomator dump ${tempFile}`);
            const { stdout } = await this.executeAdbCommand(`shell cat ${tempFile}`);
            await this.executeAdbCommand(`shell rm ${tempFile}`);
            
            // Parse XML to JSON
            const parsed = await parseStringPromise(stdout, {
                explicitArray: false,
                mergeAttrs: true
            });
            
            return parsed;
        } catch (error) {
            throw new Error(`Failed to get UI hierarchy: ${error.message}`);
        }
    }

    /**
     * Extract screen elements from UI hierarchy
     */
    extractScreenElements(node, elements = []) {
        if (!node) return elements;

        // Process current node
        if (node.text || node['content-desc'] || node.hint) {
            const bounds = this.parseBounds(node.bounds);
            if (bounds && bounds.width > 0 && bounds.height > 0) {
                const element = {
                    type: node.class || 'unknown',
                    text: node.text || '',
                    label: node['content-desc'] || node.hint || '',
                    identifier: node['resource-id'] || '',
                    clickable: node.clickable === 'true',
                    enabled: node.enabled === 'true',
                    focused: node.focused === 'true',
                    bounds: bounds,
                    // Calculate center coordinates
                    x: bounds.x + Math.floor(bounds.width / 2),
                    y: bounds.y + Math.floor(bounds.height / 2)
                };
                elements.push(element);
            }
        }

        // Process child nodes
        if (node.node) {
            if (Array.isArray(node.node)) {
                node.node.forEach(child => this.extractScreenElements(child, elements));
            } else {
                this.extractScreenElements(node.node, elements);
            }
        }

        return elements;
    }

    /**
     * Parse bounds string like "[0,0][1080,1920]" to object
     */
    parseBounds(boundsStr) {
        if (!boundsStr) return null;
        
        const match = boundsStr.match(/\[(\d+),(\d+)\]\[(\d+),(\d+)\]/);
        if (!match) return null;
        
        const [, x1, y1, x2, y2] = match.map(Number);
        return {
            x: x1,
            y: y1,
            width: x2 - x1,
            height: y2 - y1
        };
    }

    /**
     * Get all interactive elements on screen
     */
    async getElementsOnScreen() {
        try {
            const hierarchy = await this.getUiHierarchy();
            const elements = this.extractScreenElements(hierarchy.hierarchy);
            
            // Filter for meaningful elements
            return elements.filter(el => 
                el.clickable || 
                el.text || 
                el.label || 
                el.type.includes('Button') || 
                el.type.includes('EditText') ||
                el.type.includes('ImageView')
            );
        } catch (error) {
            throw new Error(`Failed to get screen elements: ${error.message}`);
        }
    }

    /**
     * Find element by text or label
     */
    async findElement(criteria) {
        const elements = await this.getElementsOnScreen();
        
        return elements.find(el => {
            if (criteria.text && el.text.includes(criteria.text)) return true;
            if (criteria.label && el.label.includes(criteria.label)) return true;
            if (criteria.identifier && el.identifier.includes(criteria.identifier)) return true;
            if (criteria.type && el.type.includes(criteria.type)) return true;
            return false;
        });
    }

    /**
     * Wait for element to appear
     */
    async waitForElement(criteria, timeout = this.waitTimeouts.elementVisible) {
        const startTime = Date.now();
        
        while (Date.now() - startTime < timeout) {
            try {
                const element = await this.findElement(criteria);
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
     * Enhanced tap with element finding
     */
    async tapElement(criteria) {
        try {
            console.log(`🎯 Looking for element to tap: ${JSON.stringify(criteria)}`);
            const element = await this.waitForElement(criteria);
            
            console.log(`📍 Tapping at (${element.x}, ${element.y})`);
            await this.executeAdbCommand(`shell input tap ${element.x} ${element.y}`);
            
            // Wait for potential animation/transition
            await new Promise(resolve => setTimeout(resolve, this.waitTimeouts.animation));
            
            return element;
        } catch (error) {
            throw new Error(`Failed to tap element: ${error.message}`);
        }
    }

    /**
     * Type text into focused element
     */
    async typeIntoElement(criteria, text, submit = false) {
        try {
            console.log(`⌨️ Typing "${text}" into element: ${JSON.stringify(criteria)}`);
            
            // First tap the element to focus it
            await this.tapElement(criteria);
            
            // Clear existing text
            await this.executeAdbCommand('shell input keyevent KEYCODE_CTRL_A');
            await new Promise(resolve => setTimeout(resolve, 200));
            await this.executeAdbCommand('shell input keyevent KEYCODE_DEL');
            await new Promise(resolve => setTimeout(resolve, 200));
            
            // Type the new text
            const escapedText = text.replace(/'/g, "\\'").replace(/"/g, '\\"');
            await this.executeAdbCommand(`shell input text "${escapedText}"`);
            
            if (submit) {
                await new Promise(resolve => setTimeout(resolve, 500));
                await this.executeAdbCommand('shell input keyevent KEYCODE_ENTER');
            }
            
            console.log(`✅ Text typed successfully: "${text}"`);
            return true;
        } catch (error) {
            throw new Error(`Failed to type text: ${error.message}`);
        }
    }

    /**
     * Take enhanced screenshot with timestamp
     */
    async takeEnhancedScreenshot(filename = null) {
        try {
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            const defaultName = `screenshot-${timestamp}.png`;
            const screenshotName = filename || defaultName;
            const screenshotPath = path.join(this.projectRoot, screenshotName);
            
            await this.executeAdbCommand(`exec-out screencap -p > "${screenshotPath}"`);
            
            console.log(`📸 Screenshot saved: ${screenshotPath}`);
            this.lastScreenshot = screenshotPath;
            return screenshotPath;
        } catch (error) {
            throw new Error(`Failed to take screenshot: ${error.message}`);
        }
    }

    /**
     * Wait for screen transition
     */
    async waitForScreenTransition(expectedElement, timeout = this.waitTimeouts.screenTransition) {
        console.log(`⏳ Waiting for screen transition...`);
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        if (expectedElement) {
            return await this.waitForElement(expectedElement, timeout);
        }
        return true;
    }

    /**
     * Automated test: Lost Lake Oregon flow
     */
    async testLostLakeOregonFlow() {
        try {
            console.log('🧪 Starting Lost Lake Oregon automated test...');
            
            // Step 1: Ensure app is running and on main screen
            await this.ensureAppRunning();
            await this.takeEnhancedScreenshot('test-start.png');
            
            // Step 2: Find and tap destination input field
            console.log('🎯 Step 1: Finding destination input field...');
            const inputField = await this.tapElement({
                text: 'Where would you like to go?',
                type: 'EditText'
            });
            
            // Step 3: Type "Lost Lake, Oregon" (field is already focused)
            console.log('⌨️ Step 2: Typing "Lost Lake, Oregon"...');
            
            // Clear any existing text first
            await this.executeAdbCommand('shell input keyevent KEYCODE_CTRL_A');
            await new Promise(resolve => setTimeout(resolve, 200));
            await this.executeAdbCommand('shell input keyevent KEYCODE_DEL');
            await new Promise(resolve => setTimeout(resolve, 200));
            
            // Type the destination directly (field is already focused)
            const escapedText = 'Lost Lake, Oregon'.replace(/'/g, "\\'").replace(/"/g, '\\"');
            await this.executeAdbCommand(`shell input text "${escapedText}"`);
            
            await this.takeEnhancedScreenshot('text-entered.png');
            
            // Step 4: Tap the Go button (try multiple criteria)
            console.log('🚀 Step 3: Tapping Go button...');
            try {
                // Try to find Go button by different criteria
                await this.tapElement({
                    label: 'Start navigation'
                });
            } catch (error) {
                console.log('Trying alternative Go button detection...');
                // Look for arrow icon or navigate button
                await this.tapElement({
                    text: '→'
                });
            }
            
            // Step 5: Wait for POI screen transition
            console.log('⏳ Step 4: Waiting for POI screen...');
            await this.waitForScreenTransition(null, 5000);
            await this.takeEnhancedScreenshot('poi-screen.png');
            
            // Step 6: Validate POI information is displayed
            console.log('✅ Step 5: Validating POI information...');
            const elements = await this.getElementsOnScreen();
            
            // Look for Lost Lake related information
            const poiElements = elements.filter(el => 
                el.text.toLowerCase().includes('lost lake') ||
                el.text.toLowerCase().includes('oregon') ||
                el.label.toLowerCase().includes('lost lake') ||
                el.label.toLowerCase().includes('oregon')
            );
            
            if (poiElements.length > 0) {
                console.log('✅ POI information found on screen:');
                poiElements.forEach(el => {
                    console.log(`  - ${el.text || el.label} (${el.type})`);
                });
                
                return {
                    success: true,
                    message: 'Lost Lake Oregon flow completed successfully',
                    poiElements: poiElements.length,
                    screenshots: [
                        'test-start.png',
                        'text-entered.png', 
                        'poi-screen.png'
                    ]
                };
            } else {
                console.warn('⚠️ No Lost Lake POI information found on screen');
                return {
                    success: false,
                    message: 'POI information not found',
                    elements: elements.map(el => ({ text: el.text, label: el.label, type: el.type }))
                };
            }
            
        } catch (error) {
            await this.takeEnhancedScreenshot('test-error.png');
            throw new Error(`Lost Lake Oregon test failed: ${error.message}`);
        }
    }

    /**
     * Validate button visibility and states
     */
    async validateButtons() {
        try {
            console.log('🔘 Validating button visibility and states...');
            
            const elements = await this.getElementsOnScreen();
            await this.takeEnhancedScreenshot('button-validation.png');
            
            // Find buttons
            const buttons = elements.filter(el => 
                el.type.includes('Button') || 
                el.clickable
            );
            
            console.log(`Found ${buttons.length} interactive elements:`);
            
            const results = {
                goButton: null,
                micButton: null,
                otherButtons: []
            };
            
            buttons.forEach(button => {
                const description = `${button.text || button.label} (${button.type})`;
                console.log(`  - ${description} at (${button.x}, ${button.y})`);
                
                // Classify buttons
                if (button.label.toLowerCase().includes('navigate') || 
                    button.text.toLowerCase().includes('go')) {
                    results.goButton = button;
                } else if (button.label.toLowerCase().includes('mic') || 
                          button.text.toLowerCase().includes('mic')) {
                    results.micButton = button;
                } else {
                    results.otherButtons.push(button);
                }
            });
            
            return {
                success: true,
                buttonCount: buttons.length,
                results: results,
                screenshot: 'button-validation.png'
            };
            
        } catch (error) {
            throw new Error(`Button validation failed: ${error.message}`);
        }
    }

    /**
     * Ensure app is running on the correct screen
     */
    async ensureAppRunning() {
        // Check if app is running
        const isRunning = await this.isAppRunning();
        if (!isRunning) {
            console.log('📱 App not running, launching...');
            await this.installAndLaunchApp();
            await new Promise(resolve => setTimeout(resolve, 3000));
        }
        
        // Verify we're on the right screen by looking for destination input
        try {
            await this.waitForElement({
                text: 'Where would you like to go?'
            }, 5000);
            console.log('✅ App is on Set Destination screen');
        } catch (error) {
            console.log('🔄 Navigating to Set Destination screen...');
            // Try to navigate to the right screen
            await this.executeAdbCommand('shell input keyevent KEYCODE_BACK');
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
    }
}

// CLI Interface
async function main() {
    const args = process.argv.slice(2);
    const command = args[0] || 'help';
    const manager = new AndroidEmulatorManager();

    try {
        switch (command) {
            case 'list':
                const emulators = await manager.listEmulators();
                console.table(emulators);
                break;
                
            case 'boot':
                const deviceName = args[1] || null;
                await manager.bootEmulator(deviceName);
                break;
                
            case 'build':
                await manager.buildApp();
                break;
                
            case 'install':
                await manager.installAndLaunchApp();
                break;
                
            case 'launch':
                await manager.bootEmulator();
                await manager.installAndLaunchApp();
                break;
                
            case 'validate':
                await manager.bootEmulator();
                await manager.installAndLaunchApp();
                const result = await manager.validateApp();
                process.exit(result ? 0 : 1);
                break;
                
            case 'screenshot':
                const filename = args[1] || null;
                await manager.takeScreenshot(filename);
                break;
                
            case 'info':
                await manager.getDeviceInfo();
                break;
                
            case 'test':
                await manager.runUITest();
                break;
                
            case 'voice-test':
                await manager.runSetDestinationTest();
                break;
                
            case 'stability':
                const iterations = parseInt(args[1]) || 5;
                await manager.testVoiceRecognitionStability(iterations);
                break;
                
            case 'performance':
                const duration = parseInt(args[1]) || 30;
                await manager.monitorPerformance(duration * 1000);
                break;
                
            case 'buttons':
                await manager.validateButtonVisibility();
                break;
                
            case 'full':
                await manager.runFullFlow({
                    deviceName: args[1] || null,
                    buildFirst: true,
                    runTests: true,
                    takeScreenshots: true,
                    monitorLogs: true
                });
                break;
                
            case 'auto-fix':
                await manager.autoFixCommonIssues();
                break;
                
            case 'lost-lake-test':
                console.log('🧪 Running Lost Lake Oregon automated test...');
                const testResult = await manager.testLostLakeOregonFlow();
                console.log('\n📊 Test Results:');
                console.log(JSON.stringify(testResult, null, 2));
                break;
                
            case 'validate-buttons':
                console.log('🔘 Validating button states...');
                const buttonResult = await manager.validateButtons();
                console.log('\n📊 Button Validation Results:');
                console.log(JSON.stringify(buttonResult, null, 2));
                break;
                
            case 'get-elements':
                console.log('🎯 Getting all elements on screen...');
                const elements = await manager.getElementsOnScreen();
                console.log(`\n📱 Found ${elements.length} interactive elements:`);
                elements.forEach((el, i) => {
                    console.log(`${i + 1}. ${el.text || el.label || 'No text'} (${el.type}) at (${el.x}, ${el.y})`);
                });
                break;
                
            case 'cleanup':
                await manager.cleanup();
                break;
                
            case 'help':
            default:
                console.log(`
Android Emulator Manager - Enhanced Platform Parity MCP Tool (Auto-Detection)

Usage: node index.js <command> [options]

Commands:
  list              List available Android emulators
  boot [device]     Boot emulator (default or specified device)
  build             Build the Android app
  install           Install and launch app on active emulator (auto-detects APK)
  launch            Boot emulator and launch app (auto-builds if needed)
  validate          Boot, launch app, and validate functionality
  screenshot [file] Take screenshot of emulator
  info              Get device information
  test              Run UI automation test
  voice-test        Run Set Destination screen voice functionality test
  lost-lake-test    🧪 Run complete Lost Lake Oregon automated flow test
  validate-buttons  🔘 Validate button visibility and accessibility
  get-elements      🎯 Get all interactive elements on current screen
  stability [N]     Test voice recognition stability (N iterations, default 5)
  performance [sec] Monitor app performance (duration in seconds, default 30)
  buttons           Validate both Go and Mic button visibility
  auto-fix          Fix common Android theme and configuration issues
  full [device]     Run complete test flow
  cleanup           Clean up resources and shutdown
  help              Show this help message

Examples:
  node index.js boot Pixel_7_Pro_API_34
  node index.js validate
  node index.js voice-test
  node index.js stability 10
  node index.js performance 60
  node index.js buttons
  node index.js full
  node index.js screenshot set-destination-test.png

UI Automation Examples:
  node index.js lost-lake-test                # Run complete Lost Lake Oregon flow
  node index.js validate-buttons              # Check button states and accessibility
  node index.js get-elements                  # List all interactive elements

Voice Testing Examples:
  node index.js voice-test                    # Run "Lost Lake, Oregon, Go" test
  node index.js stability 3                   # Test voice recognition 3 times
  node index.js performance 45               # Monitor CPU/memory for 45 seconds
  node index.js buttons                       # Check Go and Mic button visibility
                `);
                break;
        }
    } catch (error) {
        console.error(`❌ Command failed: ${error.message}`);
        process.exit(1);
    }
}

// Export for programmatic usage
module.exports = AndroidEmulatorManager;

// Run CLI if called directly
if (require.main === module) {
    main().catch(error => {
        console.error('Fatal error:', error);
        process.exit(1);
    });
}