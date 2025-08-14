#!/usr/bin/env node

/**
 * XCUITest-based iOS Simulator UI Testing Tool
 * Provides proper XCUITest integration for SwiftUI accessibility identifier testing
 */

const { execSync, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

class XCUITestRunner {
    constructor() {
        this.projectPath = null;
        this.scheme = null;
        this.bundleId = null;
        this.deviceName = 'iPhone 16 Pro';
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
     * Set project configuration
     */
    setProject(projectPath, scheme, bundleId) {
        this.projectPath = projectPath;
        this.scheme = scheme;
        this.bundleId = bundleId;
        console.log(`📱 Project configured: ${scheme} at ${projectPath}`);
    }

    /**
     * Generate XCUITest code for a specific test
     */
    generateXCUITestCode(testName, testActions) {
        const testCode = `
import XCTest

class ${testName}: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Wait for app to be ready
        sleep(2)
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    ${testActions.map(action => this.generateActionCode(action)).join('\n    ')}
}
`;
        return testCode;
    }

    /**
     * Generate individual action code
     */
    generateActionCode(action) {
        switch (action.type) {
            case 'tap':
                return `
    func test${action.name || 'TapAction'}() throws {
        let element = app.${action.elementType || 'buttons'}["${action.identifier}"]
        XCTAssertTrue(element.waitForExistence(timeout: ${action.timeout || 5}), "Element '${action.identifier}' not found")
        element.tap()
        sleep(${action.wait || 1})
    }`;

            case 'typeText':
                return `
    func test${action.name || 'TypeAction'}() throws {
        let textField = app.textFields["${action.identifier}"]
        XCTAssertTrue(textField.waitForExistence(timeout: ${action.timeout || 5}), "Text field '${action.identifier}' not found")
        textField.tap()
        textField.clearAndEnterText("${action.text}")
        sleep(${action.wait || 1})
    }`;

            case 'waitFor':
                return `
    func test${action.name || 'WaitAction'}() throws {
        let element = app.${action.elementType || 'otherElements'}["${action.identifier}"]
        XCTAssertTrue(element.waitForExistence(timeout: ${action.timeout || 10}), "Element '${action.identifier}' did not appear")
    }`;

            case 'assertExists':
                return `
    func test${action.name || 'AssertAction'}() throws {
        let element = app.${action.elementType || 'otherElements'}["${action.identifier}"]
        XCTAssertTrue(element.exists, "Element '${action.identifier}' should exist")
    }`;

            case 'screenshot':
                return `
    func test${action.name || 'ScreenshotAction'}() throws {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "${action.name || 'Screenshot'}"
        attachment.lifetime = .keepAlways
        add(attachment)
    }`;

            default:
                return `// Unknown action type: ${action.type}`;
        }
    }

    /**
     * Create a complete UI test file
     */
    createUITestFile(testName, actions, outputPath = null) {
        const testCode = this.generateXCUITestCode(testName, actions);
        const fileName = `${testName}.swift`;
        const filePath = outputPath || path.join(process.cwd(), fileName);
        
        fs.writeFileSync(filePath, testCode);
        console.log(`📝 Generated XCUITest file: ${filePath}`);
        return filePath;
    }

    /**
     * Run XCUITest from command line
     */
    runXCUITest(testName, destination = null) {
        if (!this.projectPath || !this.scheme) {
            console.error('❌ Project not configured. Use setProject() first.');
            return false;
        }

        const dest = destination || `platform=iOS Simulator,name=${this.deviceName}`;
        const command = `xcodebuild test -project "${this.projectPath}" -scheme "${this.scheme}" -destination "${dest}" -only-testing:${testName}`;
        
        console.log(`🧪 Running XCUITest: ${testName}`);
        console.log(`Command: ${command}`);
        
        const result = this.exec(command);
        return result !== null;
    }

    /**
     * Build the project for testing
     */
    buildForTesting(destination = null) {
        if (!this.projectPath || !this.scheme) {
            console.error('❌ Project not configured. Use setProject() first.');
            return false;
        }

        const dest = destination || `platform=iOS Simulator,name=${this.deviceName}`;
        const command = `xcodebuild build-for-testing -project "${this.projectPath}" -scheme "${this.scheme}" -destination "${dest}"`;
        
        console.log(`🔨 Building for testing...`);
        const result = this.exec(command);
        return result !== null;
    }

    /**
     * Get accessibility hierarchy using xcodebuild test
     */
    getAccessibilityHierarchy() {
        const hierarchyTest = this.createUITestFile('AccessibilityHierarchyTest', [
            {
                type: 'custom',
                code: `
    func testPrintAccessibilityHierarchy() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)
        
        print("=== ACCESSIBILITY HIERARCHY ===")
        printElementHierarchy(app, level: 0)
        print("=== END HIERARCHY ===")
    }
    
    private func printElementHierarchy(_ element: XCUIElement, level: Int) {
        let indent = String(repeating: "  ", count: level)
        let elementType = String(describing: type(of: element))
        let identifier = element.identifier.isEmpty ? "no-id" : element.identifier
        let label = element.label.isEmpty ? "no-label" : element.label
        
        print("\\(indent)\\(elementType): id=\\(identifier), label=\\(label)")
        
        for child in element.children(matching: .any) {
            printElementHierarchy(child, level: level + 1)
        }
    }`
            }
        ]);
        
        return this.runXCUITest('AccessibilityHierarchyTest');
    }

    /**
     * Test specific accessibility identifier
     */
    testAccessibilityIdentifier(identifier, elementType = 'any', timeout = 5) {
        const testActions = [
            {
                type: 'custom',
                code: `
    func testAccessibilityIdentifier() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)
        
        let element = app.${elementType === 'any' ? 'descendants(matching: .any)' : elementType}["${identifier}"]
        
        if element.waitForExistence(timeout: ${timeout}) {
            print("✅ Found element with identifier: ${identifier}")
            print("  - Element type: \\(type(of: element))")
            print("  - Label: \\(element.label)")
            print("  - Value: \\(element.value ?? "nil")")
            print("  - Frame: \\(element.frame)")
            print("  - Exists: \\(element.exists)")
            print("  - Hittable: \\(element.isHittable)")
        } else {
            print("❌ Element with identifier '${identifier}' not found after ${timeout} seconds")
            
            print("Available identifiers:")
            for element in app.descendants(matching: .any) {
                if !element.identifier.isEmpty {
                    print("  - \\(element.identifier) (\\(type(of: element)))")
                }
            }
        }
    }`
            }
        ];

        const testFile = this.createUITestFile('AccessibilityIdentifierTest', testActions);
        return this.runXCUITest('AccessibilityIdentifierTest');
    }

    /**
     * Create Lost Lake Oregon destination test
     */
    createLostLakeTest() {
        const testActions = [
            {
                type: 'screenshot',
                name: 'InitialState'
            },
            {
                type: 'custom',
                code: `
    func testLostLakeOregonFlow() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(3) // Wait for app to load
        
        // Take initial screenshot
        let initialScreenshot = app.screenshot()
        let initialAttachment = XCTAttachment(screenshot: initialScreenshot)
        initialAttachment.name = "Initial State"
        initialAttachment.lifetime = .keepAlways
        add(initialAttachment)
        
        print("=== Testing Lost Lake, Oregon destination flow ===")
        
        // First, let's find all available text fields
        print("Available text fields:")
        for textField in app.textFields {
            print("  - TextField: id='\\(textField.identifier)', label='\\(textField.label)'")
        }
        
        // Try to find the destination search field
        let searchField = app.textFields["destinationSearchField"]
        
        if searchField.waitForExistence(timeout: 5) {
            print("✅ Found destination search field")
            searchField.tap()
            sleep(1)
            
            // Clear and enter destination
            searchField.clearAndEnterText("Lost Lake, Oregon")
            sleep(2)
            
            // Take screenshot after entering text
            let afterTypeScreenshot = app.screenshot()
            let afterTypeAttachment = XCTAttachment(screenshot: afterTypeScreenshot)
            afterTypeAttachment.name = "After Typing Destination"
            afterTypeAttachment.lifetime = .keepAlways
            add(afterTypeAttachment)
            
            // Look for navigation button
            print("Looking for navigate button...")
            let navigateButton = app.buttons["navigateButton"]
            
            if navigateButton.waitForExistence(timeout: 3) {
                print("✅ Found navigate button, tapping...")
                navigateButton.tap()
                sleep(5)
                
                // Take final screenshot
                let finalScreenshot = app.screenshot()
                let finalAttachment = XCTAttachment(screenshot: finalScreenshot)
                finalAttachment.name = "After Navigation"
                finalAttachment.lifetime = .keepAlways
                add(finalAttachment)
                
                print("✅ Navigation completed successfully")
            } else {
                print("❌ Navigate button not found")
                print("Available buttons:")
                for button in app.buttons {
                    print("  - Button: id='\\(button.identifier)', label='\\(button.label)'")
                }
            }
            
        } else {
            print("❌ Destination search field not found")
            print("Available elements with identifiers:")
            for element in app.descendants(matching: .any) {
                if !element.identifier.isEmpty {
                    print("  - \\(type(of: element)): id='\\(element.identifier)', label='\\(element.label)'")
                }
            }
        }
        
        print("=== Test completed ===")
    }`
            }
        ];

        return this.createUITestFile('LostLakeOregonTest', testActions);
    }

    /**
     * Create and run the Lost Lake test
     */
    runLostLakeTest() {
        const testFile = this.createLostLakeTest();
        console.log(`📱 Running Lost Lake, Oregon destination test...`);
        return this.runXCUITest('LostLakeOregonTest');
    }
}

// Extension for XCUIElement to add clearAndEnterText
const xcuiExtensions = `
extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            self.typeText(text)
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
`;

// CLI interface
function main() {
    const args = process.argv.slice(2);
    const command = args[0];
    const runner = new XCUITestRunner();

    switch (command) {
        case 'setup':
            const projectPath = args[1];
            const scheme = args[2];
            const bundleId = args[3];
            runner.setProject(projectPath, scheme, bundleId);
            console.log('✅ Project setup complete');
            break;

        case 'build':
            const buildSuccess = runner.buildForTesting(args[1]);
            console.log(buildSuccess ? '✅ Build successful' : '❌ Build failed');
            break;

        case 'hierarchy':
            runner.getAccessibilityHierarchy();
            break;

        case 'test-id':
            const identifier = args[1];
            const elementType = args[2] || 'any';
            const timeout = parseInt(args[3]) || 5;
            runner.testAccessibilityIdentifier(identifier, elementType, timeout);
            break;

        case 'lost-lake':
            runner.runLostLakeTest();
            break;

        case 'create-test':
            const testName = args[1];
            const actions = JSON.parse(args[2] || '[]');
            runner.createUITestFile(testName, actions);
            break;

        case 'run-test':
            const runTestName = args[1];
            const destination = args[2];
            runner.runXCUITest(runTestName, destination);
            break;

        default:
            console.log(`
XCUITest-based iOS Simulator UI Testing Tool

Usage: node xcuitest-runner.js <command> [args]

Setup Commands:
  setup <project-path> <scheme> <bundle-id>  - Configure project for testing

Build Commands:
  build [destination]                        - Build project for testing

Testing Commands:
  hierarchy                                  - Print accessibility hierarchy
  test-id <identifier> [type] [timeout]     - Test specific accessibility identifier
  lost-lake                                 - Run Lost Lake, Oregon destination test
  create-test <name> <actions-json>         - Create custom XCUITest file
  run-test <test-name> [destination]        - Run specific XCUITest

Examples:
  node xcuitest-runner.js setup "/path/to/Project.xcodeproj" "AppScheme" "com.app.bundle"
  node xcuitest-runner.js build
  node xcuitest-runner.js hierarchy
  node xcuitest-runner.js test-id "destinationSearchField" "textFields" 10
  node xcuitest-runner.js lost-lake

Project Structure:
  Your Xcode project should include XCUITest target for proper testing.
  
Note: This tool generates and runs actual XCUITests, providing reliable
      SwiftUI accessibility identifier testing capabilities.
`);
    }
}

// Export for use as module
module.exports = XCUITestRunner;

// Run if called directly
if (require.main === module) {
    main();
}