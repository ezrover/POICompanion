#!/usr/bin/env node

/**
 * iOS Simulator UI Interaction Tool
 * Provides tap, swipe, type, and press capabilities for iOS simulator testing
 */

const { execSync, spawn } = require('child_process');
import path from 'path';
import fs from 'fs';

class SimulatorUI {
    constructor() {
        this.deviceName = null;
        this.bundleId = null;
    }

    /**
     * Execute a command and return output
     */
    exec(command, silent = false) {
        try {
            const output = execSync(command, { encoding: 'utf8', stdio: silent ? 'pipe' : 'inherit' });
            return output;
        } catch (error) {
            if (!silent) {
                console.error(`Command failed: ${command}`);
                console.error(error.message);
            }
            return null;
        }
    }

    /**
     * Get booted device or specific device
     */
    getDevice(deviceName = null) {
        if (deviceName) {
            return deviceName;
        }
        
        // Get booted device
        const devices = this.exec('xcrun simctl list devices booted -j', true);
        if (devices) {
            const json = JSON.parse(devices);
            const bootedDevices = Object.values(json.devices).flat();
            if (bootedDevices.length > 0) {
                return bootedDevices[0].name;
            }
        }
        
        return 'iPhone 16 Pro'; // Default
    }

    /**
     * Tap at coordinates
     */
    tap(x, y, deviceName = null) {
        const device = this.getDevice(deviceName);
        console.log(`📱 Tapping at (${x}, ${y}) on ${device}`);
        
        // Use separate AppleScript commands
        this.exec(`osascript -e 'tell application "Simulator" to activate'`);
        this.exec(`sleep 0.5`);
        
        // Click at position using GUI scripting
        const clickScript = `osascript -e 'tell application "System Events" to tell process "Simulator" to click at {${x}, ${y}}'`;
        this.exec(clickScript);
        
        return { success: true, action: 'tap', x, y };
    }

    /**
     * Type text into active field
     */
    type(text, deviceName = null) {
        const device = this.getDevice(deviceName);
        console.log(`⌨️  Typing: "${text}" on ${device}`);
        
        // Escape special characters for AppleScript
        const escapedText = text.replace(/"/g, '\\"').replace(/'/g, "\\'");
        
        // Use separate commands
        this.exec(`osascript -e 'tell application "Simulator" to activate'`);
        this.exec(`sleep 0.5`);
        this.exec(`osascript -e 'tell application "System Events" to tell process "Simulator" to keystroke "${escapedText}"'`);
        
        return { success: true, action: 'type', text };
    }

    /**
     * Press a key (return, delete, escape, etc.)
     */
    press(key, deviceName = null) {
        const device = this.getDevice(deviceName);
        console.log(`⌨️  Pressing: ${key} on ${device}`);
        
        const keyMap = {
            'return': 'return',
            'enter': 'return',
            'delete': 'delete',
            'backspace': 'delete',
            'escape': 'escape',
            'esc': 'escape',
            'tab': 'tab',
            'space': 'space',
            'up': 'up arrow',
            'down': 'down arrow',
            'left': 'left arrow',
            'right': 'right arrow'
        };
        
        const mappedKey = keyMap[key.toLowerCase()] || key;
        
        // Use separate commands
        this.exec(`osascript -e 'tell application "Simulator" to activate'`);
        this.exec(`sleep 0.5`);
        this.exec(`osascript -e 'tell application "System Events" to tell process "Simulator" to key code ${this.getKeyCode(mappedKey)}'`);
        
        return { success: true, action: 'press', key };
    }

    /**
     * Get key code for special keys
     */
    getKeyCode(key) {
        const codes = {
            'return': '36',
            'delete': '51',
            'escape': '53',
            'tab': '48',
            'space': '49',
            'up arrow': '126',
            'down arrow': '125',
            'left arrow': '123',
            'right arrow': '124'
        };
        return codes[key] || '36'; // Default to return
    }

    /**
     * Swipe gesture
     */
    swipe(fromX, fromY, toX, toY, duration = 0.5, deviceName = null) {
        const device = this.getDevice(deviceName);
        console.log(`👆 Swiping from (${fromX}, ${fromY}) to (${toX}, ${toY}) on ${device}`);
        
        const script = `
            tell application "Simulator"
                activate
            end tell
            
            tell application "System Events"
                tell process "Simulator"
                    set frontmost to true
                    delay 0.5
                    click at {${fromX}, ${fromY}}
                    delay 0.1
                    drag from {${fromX}, ${fromY}} to {${toX}, ${toY}}
                end tell
            end tell
        `;
        
        this.exec(`osascript -e '${script.replace(/\n/g, ' ')}'`);
        return { success: true, action: 'swipe', fromX, fromY, toX, toY };
    }

    /**
     * Long press at coordinates
     */
    longPress(x, y, duration = 1.0, deviceName = null) {
        const device = this.getDevice(deviceName);
        console.log(`👆 Long pressing at (${x}, ${y}) for ${duration}s on ${device}`);
        
        const script = `
            tell application "Simulator"
                activate
            end tell
            
            tell application "System Events"
                tell process "Simulator"
                    set frontmost to true
                    delay 0.5
                    click at {${x}, ${y}}
                    delay ${duration}
                end tell
            end tell
        `;
        
        this.exec(`osascript -e '${script.replace(/\n/g, ' ')}'`);
        return { success: true, action: 'longPress', x, y, duration };
    }

    /**
     * Take screenshot
     */
    screenshot(outputPath = '/tmp/screenshot.png', deviceName = null) {
        const device = this.getDevice(deviceName);
        console.log(`📸 Taking screenshot of ${device}`);
        
        this.exec(`xcrun simctl io "${device}" screenshot "${outputPath}"`);
        return { success: true, action: 'screenshot', path: outputPath };
    }

    /**
     * Get screen size
     */
    getScreenSize(deviceName = null) {
        const device = this.getDevice(deviceName);
        
        // Common iOS device resolutions
        const resolutions = {
            'iPhone 16 Pro': { width: 393, height: 852 },
            'iPhone 16 Pro Max': { width: 430, height: 932 },
            'iPhone 15 Pro': { width: 393, height: 852 },
            'iPhone 14 Pro': { width: 393, height: 852 },
            'iPhone 13 Pro': { width: 390, height: 844 },
            'iPhone 12 Pro': { width: 390, height: 844 },
            'iPad Pro': { width: 1024, height: 1366 }
        };
        
        return resolutions[device] || { width: 393, height: 852 };
    }

    /**
     * Clear text field (select all and delete)
     */
    clearField(deviceName = null) {
        console.log(`🧹 Clearing text field`);
        
        // Command+A to select all, then delete
        const script = `
            tell application "Simulator"
                activate
            end tell
            
            tell application "System Events"
                tell process "Simulator"
                    set frontmost to true
                    delay 0.5
                    keystroke "a" using command down
                    delay 0.1
                    key code 51
                end tell
            end tell
        `;
        
        this.exec(`osascript -e '${script.replace(/\n/g, ' ')}'`);
        return { success: true, action: 'clearField' };
    }

    /**
     * Wait/delay
     */
    wait(seconds) {
        console.log(`⏱️  Waiting ${seconds} seconds...`);
        this.exec(`sleep ${seconds}`);
        return { success: true, action: 'wait', duration: seconds };
    }
}

// CLI interface
function main() {
    const args = process.argv.slice(2);
    const command = args[0];
    const ui = new SimulatorUI();

    switch (command) {
        case 'tap':
            const x = parseInt(args[1]);
            const y = parseInt(args[2]);
            ui.tap(x, y, args[3]);
            break;

        case 'type':
            const text = args.slice(1).join(' ');
            ui.type(text);
            break;

        case 'press':
            ui.press(args[1]);
            break;

        case 'swipe':
            const fx = parseInt(args[1]);
            const fy = parseInt(args[2]);
            const tx = parseInt(args[3]);
            const ty = parseInt(args[4]);
            ui.swipe(fx, fy, tx, ty, args[5] || 0.5);
            break;

        case 'longpress':
            const lx = parseInt(args[1]);
            const ly = parseInt(args[2]);
            ui.longPress(lx, ly, args[3] || 1.0);
            break;

        case 'screenshot':
            ui.screenshot(args[1] || '/tmp/screenshot.png');
            break;

        case 'clear':
            ui.clearField();
            break;

        case 'wait':
            ui.wait(parseFloat(args[1]) || 1);
            break;

        case 'test':
            // Test sequence
            console.log('🧪 Running UI test sequence...');
            ui.tap(200, 650); // Tap search field
            ui.wait(1);
            ui.type('Lost Lake, Oregon');
            ui.wait(1);
            ui.press('return');
            ui.wait(2);
            ui.screenshot('/tmp/test-result.png');
            console.log('✅ Test complete!');
            break;

        default:
            console.log(`
iOS Simulator UI Interaction Tool

Usage: node index.js <command> [args]

Commands:
  tap <x> <y> [device]           - Tap at coordinates
  type <text> [device]           - Type text into active field
  press <key> [device]           - Press a key (return, delete, escape, etc.)
  swipe <x1> <y1> <x2> <y2>      - Swipe from point to point
  longpress <x> <y> [duration]   - Long press at coordinates
  screenshot [path] [device]     - Take a screenshot
  clear [device]                 - Clear active text field
  wait <seconds>                 - Wait for specified seconds
  test                          - Run test sequence

Examples:
  node index.js tap 200 400
  node index.js type "Hello World"
  node index.js press return
  node index.js swipe 100 500 100 200
  node index.js screenshot /tmp/screen.png
`);
    }
}

// Export for use as module
module.exports = SimulatorUI;

// Run if called directly
if (require.main === module) {
    main();
}