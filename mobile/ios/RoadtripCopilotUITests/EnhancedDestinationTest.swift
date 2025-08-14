import XCTest

class EnhancedDestinationTest: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Add debugging launch arguments
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["TEST_MODE": "true"]
        
        app.launch()
        
        // Wait for app to fully load
        sleep(3)
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testAccessibilityIdentifiersExist() throws {
        print("🔍 Testing accessibility identifiers exist...")
        
        // Take initial screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Initial App State"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Print all available identifiers for debugging
        print("=== Available Accessibility Identifiers ===")
        printAllAccessibilityIdentifiers()
        
        // Look for the search field using our identifier
        let searchField = app.textFields["destinationSearchField"]
        
        if searchField.waitForExistence(timeout: 5) {
            print("✅ Found search field with identifier: destinationSearchField")
            XCTAssertTrue(searchField.exists)
        } else {
            print("❌ Search field 'destinationSearchField' not found")
            print("Available text fields:")
            for textField in app.textFields.allElementsBoundByIndex {
                print("  - TextField: '\(textField.identifier)' label: '\(textField.label)'")
            }
            XCTFail("Search field with identifier 'destinationSearchField' should exist")
        }
        
        // Look for navigation button
        let navigateButton = app.buttons["navigateButton"]
        
        if navigateButton.waitForExistence(timeout: 2) {
            print("✅ Found navigate button with identifier: navigateButton")
            XCTAssertTrue(navigateButton.exists)
        } else {
            print("❌ Navigate button 'navigateButton' not found")
            print("Available buttons:")
            for button in app.buttons.allElementsBoundByIndex {
                print("  - Button: '\(button.identifier)' label: '\(button.label)'")
            }
            XCTFail("Navigate button with identifier 'navigateButton' should exist")
        }
        
        // Look for microphone button
        let micButton = app.buttons["microphoneButton"]
        
        if micButton.waitForExistence(timeout: 2) {
            print("✅ Found microphone button with identifier: microphoneButton")
            XCTAssertTrue(micButton.exists)
        } else {
            print("❌ Microphone button 'microphoneButton' not found")
        }
    }
    
    func testLostLakeOregonDestinationFlow() throws {
        print("🧪 Testing Lost Lake, Oregon destination flow...")
        
        // Step 1: Find and tap search field
        let searchField = app.textFields["destinationSearchField"]
        
        if searchField.waitForExistence(timeout: 5) {
            print("✅ Found search field, tapping and typing...")
            
            // Tap and clear the field
            searchField.tap()
            sleep(1)
            
            // Clear existing text and enter destination
            if let currentText = searchField.value as? String, !currentText.isEmpty {
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentText.count)
                searchField.typeText(deleteString)
            }
            
            searchField.typeText("Lost Lake, Oregon")
            sleep(2)
            
            // Take screenshot after entering text
            let afterTextScreenshot = app.screenshot()
            let afterTextAttachment = XCTAttachment(screenshot: afterTextScreenshot)
            afterTextAttachment.name = "After Entering Destination"
            afterTextAttachment.lifetime = .keepAlways
            add(afterTextAttachment)
            
            // Step 2: Tap navigation button
            let navigateButton = app.buttons["navigateButton"]
            
            if navigateButton.waitForExistence(timeout: 3) {
                print("✅ Found navigate button, tapping...")
                navigateButton.tap()
                sleep(5) // Wait for navigation to complete
                
                // Take screenshot after navigation
                let afterNavScreenshot = app.screenshot()
                let afterNavAttachment = XCTAttachment(screenshot: afterNavScreenshot)
                afterNavAttachment.name = "After Navigation Tap"
                afterNavAttachment.lifetime = .keepAlways
                add(afterNavAttachment)
                
                // Step 3: Check if we're now in MainPOIView
                print("🔍 Checking if we're in MainPOIView...")
                
                // Look for MainPOIView-specific elements
                let backButton = app.buttons["backButton"]
                let appTitle = app.staticTexts["appTitle"]
                
                if backButton.waitForExistence(timeout: 5) {
                    print("✅ Successfully navigated to MainPOIView - found back button")
                    XCTAssertTrue(backButton.exists, "Should be in MainPOIView with back button")
                    
                    // Take final success screenshot
                    let successScreenshot = app.screenshot()
                    let successAttachment = XCTAttachment(screenshot: successScreenshot)
                    successAttachment.name = "Successfully in MainPOIView"
                    successAttachment.lifetime = .keepAlways
                    add(successAttachment)
                    
                } else if appTitle.waitForExistence(timeout: 3) {
                    print("✅ Found app title, likely in MainPOIView")
                    XCTAssertTrue(appTitle.exists)
                } else {
                    print("❌ Navigation may have failed - neither back button nor app title found")
                    printAllAccessibilityIdentifiers()
                    XCTFail("Should have navigated to MainPOIView")
                }
                
            } else {
                print("❌ Navigate button not found after entering text")
                printAllAccessibilityIdentifiers()
                XCTFail("Navigate button should be available after entering destination")
            }
            
        } else {
            print("❌ Search field not found")
            printAllAccessibilityIdentifiers()
            XCTFail("Search field with identifier 'destinationSearchField' should exist")
        }
        
        print("✅ Lost Lake, Oregon destination test completed")
    }
    
    func testMainPOIViewElements() throws {
        print("🧪 Testing MainPOIView elements...")
        
        // First navigate to MainPOIView
        let searchField = app.textFields["destinationSearchField"]
        if searchField.waitForExistence(timeout: 5) {
            searchField.tap()
            searchField.typeText("Lost Lake, Oregon")
            
            let navigateButton = app.buttons["navigateButton"]
            if navigateButton.waitForExistence(timeout: 3) {
                navigateButton.tap()
                sleep(5)
                
                // Now test MainPOIView elements
                let mainPOIElements = [
                    "backButton",
                    "destinationInfo", 
                    "speedIndicator",
                    "locationInfo",
                    "previousPOIButton",
                    "savePOIButton",
                    "likePOIButton",
                    "dislikePOIButton",
                    "navigatePOIButton",
                    "callPOIButton",
                    "exitPOIButton",
                    "nextPOIButton"
                ]
                
                var foundElements: [String] = []
                
                for elementId in mainPOIElements {
                    if app.buttons[elementId].exists || app.staticTexts[elementId].exists || app.otherElements[elementId].exists {
                        foundElements.append(elementId)
                        print("✅ Found element: \(elementId)")
                    } else {
                        print("❌ Missing element: \(elementId)")
                    }
                }
                
                print("Found \(foundElements.count) out of \(mainPOIElements.count) MainPOIView elements")
                XCTAssertTrue(foundElements.count >= mainPOIElements.count / 2, "Should find at least half of MainPOIView elements")
            }
        }
    }
    
    private func printAllAccessibilityIdentifiers() {
        print("=== All Accessibility Identifiers ===")
        
        // Text Fields
        print("Text Fields:")
        for textField in app.textFields.allElementsBoundByIndex {
            if !textField.identifier.isEmpty {
                print("  - TextField: '\(textField.identifier)' (label: '\(textField.label)')")
            }
        }
        
        // Buttons
        print("Buttons:")
        for button in app.buttons.allElementsBoundByIndex {
            if !button.identifier.isEmpty {
                print("  - Button: '\(button.identifier)' (label: '\(button.label)')")
            }
        }
        
        // Static Texts
        print("Static Texts:")
        for text in app.staticTexts.allElementsBoundByIndex {
            if !text.identifier.isEmpty {
                print("  - StaticText: '\(text.identifier)' (label: '\(text.label)')")
            }
        }
        
        // Other Elements
        print("Other Elements:")
        for element in app.otherElements.allElementsBoundByIndex {
            if !element.identifier.isEmpty {
                print("  - OtherElement: '\(element.identifier)' (label: '\(element.label)')")
            }
        }
        
        print("=== End Accessibility Identifiers ===")
    }
}

// MARK: - XCUIElement Extension
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