#!/usr/bin/env node

/**
 * Enhanced iOS Simulator UI Interaction Tool
 * Provides accessibility identifier-based UI interactions for iOS simulator testing
 */

const { execSync, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

class EnhancedSimulatorUI {
    constructor() {
        this.deviceName = null;
        this.bundleId = null;
        this.deviceId = null;
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
     * Get device ID for booted device
     */
    getDeviceId() {
        if (this.deviceId) return this.deviceId;
        
        const devices = this.exec('xcrun simctl list devices booted -j', true);
        if (devices) {
            const json = JSON.parse(devices);
            const bootedDevices = Object.values(json.devices).flat();
            if (bootedDevices.length > 0) {
                this.deviceId = bootedDevices[0].udid;
                this.deviceName = bootedDevices[0].name;
                return this.deviceId;
            }
        }
        return null;
    }

    /**
     * Get accessibility tree/hierarchy of current app
     */
    getAccessibilityTree() {
        const deviceId = this.getDeviceId();
        if (!deviceId) {
            console.error('No booted device found');
            return null;
        }

        console.log('📱 Getting accessibility tree...');
        
        // Use accessibility inspector to get UI tree
        const script = `
            tell application "System Events"
                tell process "Simulator"
                    set frontmost to true
                    delay 0.5
                    -- Try to get all UI elements
                    return every UI element
                end tell
            end tell
        `;
        
        const result = this.exec(`osascript -e '${script.replace(/\n/g, ' ')}'`, true);
        return result;
    }

    /**
     * Find element by accessibility identifier
     */
    findElementByIdentifier(identifier, timeout = 5) {
        const deviceId = this.getDeviceId();
        if (!deviceId) return null;

        console.log(`🔍 Looking for element with identifier: ${identifier}`);
        
        const startTime = Date.now();
        while (Date.now() - startTime < timeout * 1000) {
            // Use AppleScript to find element by accessibility identifier
            const script = `
                tell application "System Events"
                    tell process "Simulator"
                        set frontmost to true
                        delay 0.2
                        try
                            set targetElement to first UI element whose accessibility identifier is "${identifier}"
                            if targetElement exists then
                                set elementPosition to position of targetElement
                                set elementSize to size of targetElement
                                return (item 1 of elementPosition) & "," & (item 2 of elementPosition) & "," & (item 1 of elementSize) & "," & (item 2 of elementSize)
                            end if
                        on error
                            return "not_found"
                        end try
                    end tell
                end tell
            `;
            
            const result = this.exec(`osascript -e '${script.replace(/\n/g, ' ')}'`, true);
            
            if (result && result.trim() !== 'not_found') {
                const [x, y, width, height] = result.trim().split(',').map(Number);
                console.log(`✅ Found element ${identifier} at (${x}, ${y}) size: ${width}x${height}`);
                return { x, y, width, height, centerX: x + width/2, centerY: y + height/2 };
            }
            
            // Wait a bit before retrying
            this.exec('sleep 0.5', true);
        }
        
        console.log(`❌ Element with identifier '${identifier}' not found after ${timeout}s`);
        return null;
    }

    /**
     * Find element by text content
     */
    findElementByText(text, timeout = 5) {
        const deviceId = this.getDeviceId();
        if (!deviceId) return null;

        console.log(`🔍 Looking for element with text: "${text}"`);
        
        const startTime = Date.now();
        while (Date.now() - startTime < timeout * 1000) {
            const script = `
                tell application "System Events"
                    tell process "Simulator"
                        set frontmost to true
                        delay 0.2
                        try
                            set targetElement to first UI element whose accessibility description contains "${text}" or whose accessibility title contains "${text}" or whose accessibility value contains "${text}"
                            if targetElement exists then
                                set elementPosition to position of targetElement
                                set elementSize to size of targetElement
                                return (item 1 of elementPosition) & "," & (item 2 of elementPosition) & "," & (item 1 of elementSize) & "," & (item 2 of elementSize)
                            end if
                        on error
                            return "not_found"
                        end try
                    end tell
                end tell
            `;
            
            const result = this.exec(`osascript -e '${script.replace(/\n/g, ' ')}'`, true);
            
            if (result && result.trim() !== 'not_found') {
                const [x, y, width, height] = result.trim().split(',').map(Number);
                console.log(`✅ Found element with text "${text}" at (${x}, ${y}) size: ${width}x${height}`);
                return { x, y, width, height, centerX: x + width/2, centerY: y + height/2 };
            }
            
            this.exec('sleep 0.5', true);
        }
        
        console.log(`❌ Element with text '${text}' not found after ${timeout}s`);
        return null;
    }

    /**
     * Tap element by accessibility identifier
     */
    tapByIdentifier(identifier, timeout = 5) {
        const element = this.findElementByIdentifier(identifier, timeout);
        if (!element) {
            return { success: false, error: `Element with identifier '${identifier}' not found` };
        }
        
        return this.tap(element.centerX, element.centerY);
    }

    /**
     * Tap element by text content
     */
    tapByText(text, timeout = 5) {
        const element = this.findElementByText(text, timeout);
        if (!element) {
            return { success: false, error: `Element with text '${text}' not found` };
        }
        
        return this.tap(element.centerX, element.centerY);
    }

    /**
     * Type text into element by identifier
     */
    typeIntoElement(identifier, text, timeout = 5) {
        const element = this.findElementByIdentifier(identifier, timeout);
        if (!element) {
            return { success: false, error: `Element with identifier '${identifier}' not found` };
        }
        
        // First tap to focus the element
        this.tap(element.centerX, element.centerY);
        this.wait(0.5);
        
        // Clear existing text and type new text
        this.clearField();
        this.wait(0.2);
        this.type(text);
        
        return { success: true, action: 'typeIntoElement', identifier, text };
    }

    /**
     * Get all accessibility identifiers currently visible
     */
    getAllAccessibilityIdentifiers() {
        console.log('🔍 Getting all accessibility identifiers...');
        
        const script = `
            tell application "System Events"
                tell process "Simulator"
                    set frontmost to true
                    delay 0.5
                    set allElements to every UI element
                    set identifierList to {}
                    repeat with elem in allElements
                        try
                            set elemId to accessibility identifier of elem
                            if elemId is not missing value and elemId is not "" then
                                set end of identifierList to elemId
                            end if
                        on error
                            -- Skip elements without identifiers
                        end try
                    end repeat
                    return identifierList
                end tell
            end tell
        `;
        
        const result = this.exec(`osascript -e '${script.replace(/\n/g, ' ')}'`, true);
        
        if (result) {
            // Parse AppleScript list result
            const identifiers = result.trim().replace(/^\{|\}$/g, '').split(', ');
            console.log(`📝 Found ${identifiers.length} accessibility identifiers:`);
            identifiers.forEach(id => console.log(`  - ${id}`));
            return identifiers;
        }
        
        return [];
    }

    /**
     * Wait for element to appear
     */
    waitForElement(identifier, timeout = 10) {
        console.log(`⏱️  Waiting for element '${identifier}' to appear...`);
        
        const element = this.findElementByIdentifier(identifier, timeout);
        return element !== null;
    }

    /**
     * Check if element exists
     */
    elementExists(identifier, timeout = 1) {
        const element = this.findElementByIdentifier(identifier, timeout);
        return element !== null;
    }

    /**
     * Basic tap at coordinates (inherited from base class)
     */
    tap(x, y) {
        console.log(`📱 Tapping at (${x}, ${y})`);
        
        this.exec(`osascript -e 'tell application "Simulator" to activate'`);
        this.exec(`sleep 0.5`);
        
        const clickScript = `osascript -e 'tell application "System Events" to tell process "Simulator" to click at {${x}, ${y}}'`;
        this.exec(clickScript);
        
        return { success: true, action: 'tap', x, y };
    }

    /**
     * Type text into active field
     */
    type(text) {
        console.log(`⌨️  Typing: "${text}"`);
        
        // Escape special characters for AppleScript
        const escapedText = text.replace(/"/g, '\\"').replace(/'/g, "\\'");
        
        this.exec(`osascript -e 'tell application "Simulator" to activate'`);
        this.exec(`sleep 0.5`);
        this.exec(`osascript -e 'tell application "System Events" to tell process "Simulator" to keystroke "${escapedText}"'`);
        
        return { success: true, action: 'type', text };
    }

    /**
     * Clear text field
     */
    clearField() {
        console.log(`🧹 Clearing text field`);
        
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

    /**
     * Take screenshot
     */
    screenshot(outputPath = '/tmp/screenshot.png') {
        const deviceId = this.getDeviceId();
        if (!deviceId) return { success: false, error: 'No device found' };
        
        console.log(`📸 Taking screenshot`);
        
        this.exec(`xcrun simctl io ${deviceId} screenshot "${outputPath}"`);
        return { success: true, action: 'screenshot', path: outputPath };
    }

    /**
     * Press a key
     */
    press(key) {
        console.log(`⌨️  Pressing: ${key}`);
        
        const keyMap = {
            'return': '36',
            'enter': '36',
            'delete': '51',
            'backspace': '51',
            'escape': '53',
            'tab': '48',
            'space': '49'
        };
        
        const keyCode = keyMap[key.toLowerCase()] || '36';
        
        this.exec(`osascript -e 'tell application "Simulator" to activate'`);
        this.exec(`sleep 0.5`);
        this.exec(`osascript -e 'tell application "System Events" to tell process "Simulator" to key code ${keyCode}'`);
        
        return { success: true, action: 'press', key };
    }

    /**
     * Debug: Print all visible UI elements and their properties
     */
    debugUIHierarchy() {
        console.log('🐞 Debug: Getting UI hierarchy...');
        
        const script = `
            tell application "System Events"
                tell process "Simulator"
                    set frontmost to true
                    delay 1
                    set allElements to every UI element
                    set debugInfo to {}
                    repeat with elem in allElements
                        try
                            set elemClass to class of elem as string
                            set elemId to ""
                            set elemTitle to ""
                            set elemDescription to ""
                            
                            try
                                set elemId to accessibility identifier of elem
                            end try
                            
                            try
                                set elemTitle to accessibility title of elem
                            end try
                            
                            try
                                set elemDescription to accessibility description of elem
                            end try
                            
                            if elemClass contains "text field" or elemClass contains "button" or elemId is not "" then
                                set debugLine to elemClass & " | ID: " & elemId & " | Title: " & elemTitle & " | Desc: " & elemDescription
                                set end of debugInfo to debugLine
                            end if
                        on error
                            -- Skip problematic elements
                        end try
                    end repeat
                    return debugInfo
                end tell
            end tell
        `;
        
        const result = this.exec(`osascript -e '${script.replace(/\n/g, ' ')}'`, true);
        
        if (result) {
            console.log('📝 UI Elements found:');
            const elements = result.trim().replace(/^\{|\}$/g, '').split(', ');
            elements.forEach((element, index) => {
                console.log(`  ${index + 1}. ${element}`);
            });
        }
        
        return result;
    }
}

// CLI interface
function main() {
    const args = process.argv.slice(2);
    const command = args[0];
    const ui = new EnhancedSimulatorUI();

    switch (command) {
        case 'tap-id':
            const identifier = args[1];
            const timeout = parseInt(args[2]) || 5;
            const result = ui.tapByIdentifier(identifier, timeout);
            console.log(JSON.stringify(result, null, 2));
            break;

        case 'tap-text':
            const text = args[1];
            const textTimeout = parseInt(args[2]) || 5;
            const textResult = ui.tapByText(text, textTimeout);
            console.log(JSON.stringify(textResult, null, 2));
            break;

        case 'type-into':
            const targetId = args[1];
            const inputText = args.slice(2).join(' ');
            const typeResult = ui.typeIntoElement(targetId, inputText);
            console.log(JSON.stringify(typeResult, null, 2));
            break;

        case 'find-id':
            const findId = args[1];
            const findTimeout = parseInt(args[2]) || 5;
            const element = ui.findElementByIdentifier(findId, findTimeout);
            console.log(JSON.stringify(element, null, 2));
            break;

        case 'find-text':
            const findText = args[1];
            const findTextTimeout = parseInt(args[2]) || 5;
            const textElement = ui.findElementByText(findText, findTextTimeout);
            console.log(JSON.stringify(textElement, null, 2));
            break;

        case 'list-ids':
            const identifiers = ui.getAllAccessibilityIdentifiers();
            console.log(JSON.stringify(identifiers, null, 2));
            break;

        case 'wait-for':
            const waitId = args[1];
            const waitTimeout = parseInt(args[2]) || 10;
            const exists = ui.waitForElement(waitId, waitTimeout);
            console.log(JSON.stringify({ exists, identifier: waitId }, null, 2));
            break;

        case 'exists':
            const existsId = args[1];
            const existsResult = ui.elementExists(existsId);
            console.log(JSON.stringify({ exists: existsResult, identifier: existsId }, null, 2));
            break;

        case 'debug':
            ui.debugUIHierarchy();
            break;

        case 'screenshot':
            const screenshotPath = args[1] || '/tmp/enhanced-screenshot.png';
            const screenshotResult = ui.screenshot(screenshotPath);
            console.log(JSON.stringify(screenshotResult, null, 2));
            break;

        case 'test-destination':
            // Test the Lost Lake, Oregon flow
            console.log('🧪 Testing Lost Lake, Oregon destination flow...');
            
            ui.screenshot('/tmp/test-start.png');
            ui.wait(2);
            
            // Try to find and interact with search field
            console.log('Step 1: Looking for search field...');
            ui.debugUIHierarchy();
            
            if (ui.elementExists('destinationSearchField', 3)) {
                console.log('Step 2: Found search field, typing destination...');
                ui.typeIntoElement('destinationSearchField', 'Lost Lake, Oregon');
                ui.wait(2);
                
                console.log('Step 3: Looking for Go button...');
                if (ui.elementExists('navigateButton', 3)) {
                    console.log('Step 4: Found Go button, tapping...');
                    ui.tapByIdentifier('navigateButton');
                    ui.wait(5);
                    
                    ui.screenshot('/tmp/test-after-navigate.png');
                    console.log('✅ Navigation test complete!');
                } else {
                    console.log('❌ Navigate button not found');
                }
            } else {
                console.log('❌ Search field not found');
            }
            break;

        // Basic commands from original tool
        case 'tap':
            const x = parseInt(args[1]);
            const y = parseInt(args[2]);
            ui.tap(x, y);
            break;

        case 'type':
            const typeText = args.slice(1).join(' ');
            ui.type(typeText);
            break;

        case 'press':
            ui.press(args[1]);
            break;

        case 'clear':
            ui.clearField();
            break;

        case 'wait':
            ui.wait(parseFloat(args[1]) || 1);
            break;

        default:
            console.log(`
Enhanced iOS Simulator UI Interaction Tool

Usage: node enhanced-ui.js <command> [args]

Enhanced Commands:
  tap-id <identifier> [timeout]       - Tap element by accessibility identifier
  tap-text <text> [timeout]           - Tap element by text content
  type-into <identifier> <text>       - Type text into element by identifier
  find-id <identifier> [timeout]     - Find element by identifier and return position
  find-text <text> [timeout]         - Find element by text and return position
  list-ids                           - List all accessibility identifiers
  wait-for <identifier> [timeout]   - Wait for element to appear
  exists <identifier>                - Check if element exists
  debug                             - Print UI hierarchy for debugging
  test-destination                  - Test Lost Lake, Oregon destination flow

Basic Commands:
  tap <x> <y>                       - Tap at coordinates
  type <text>                       - Type text into active field
  press <key>                       - Press a key (return, delete, escape, etc.)
  clear                            - Clear active text field
  wait <seconds>                   - Wait for specified seconds
  screenshot [path]                - Take a screenshot

Examples:
  node enhanced-ui.js tap-id destinationSearchField
  node enhanced-ui.js type-into destinationSearchField "Lost Lake, Oregon"
  node enhanced-ui.js tap-id navigateButton
  node enhanced-ui.js list-ids
  node enhanced-ui.js debug
  node enhanced-ui.js test-destination
`);
    }
}

// Export for use as module
module.exports = EnhancedSimulatorUI;

// Run if called directly
if (require.main === module) {
    main();
}