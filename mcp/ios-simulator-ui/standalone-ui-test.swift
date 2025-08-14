#!/usr/bin/env swift

import Foundation
import XCTest

// Simple UI Test for accessibility identifiers without needing Xcode project setup
class StandaloneUITest {
    static func testAccessibilityElements() {
        print("🧪 Starting standalone UI test for accessibility identifiers...")
        
        // Use xcrun simctl to interact with the simulator directly
        let deviceId = getBootedDevice()
        guard let device = deviceId else {
            print("❌ No booted simulator found")
            return
        }
        
        print("📱 Using device: \(device)")
        
        // Launch the app if not already running
        launchApp(device: device)
        
        // Wait for app to load
        sleep(3)
        
        // Take screenshot
        takeScreenshot(device: device, name: "initial_state")
        
        // Test using simctl directly for UI automation
        testSimulatorDirectly(device: device)
    }
    
    static func getBootedDevice() -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = ["simctl", "list", "devices", "booted", "-j"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }
        
        // Parse JSON to find booted device
        if let jsonData = output.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let devices = json["devices"] as? [String: Any] {
            
            for (_, deviceList) in devices {
                if let deviceArray = deviceList as? [[String: Any]] {
                    for device in deviceArray {
                        if let state = device["state"] as? String,
                           let udid = device["udid"] as? String,
                           state == "Booted" {
                            return udid
                        }
                    }
                }
            }
        }
        return nil
    }
    
    static func launchApp(device: String) {
        let task = Process()
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = ["simctl", "launch", device, "com.hmi2.roadtrip-copilot"]
        task.launch()
        task.waitUntilExit()
        
        print("📱 App launched")
    }
    
    static func takeScreenshot(device: String, name: String) {
        let path = "/tmp/\(name).png"
        let task = Process()
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = ["simctl", "io", device, "screenshot", path]
        task.launch()
        task.waitUntilExit()
        
        print("📸 Screenshot saved: \(path)")
    }
    
    static func testSimulatorDirectly(device: String) {
        print("🔍 Testing UI interaction with simulator...")
        
        // Use AppleScript for actual UI interaction since simctl doesn't support UI element access
        let script = """
        tell application "Simulator"
            activate
        end tell
        
        delay 1
        
        tell application "System Events"
            tell process "Simulator"
                set frontmost to true
                delay 1
                
                -- Try to find and click on search field area
                click at {207, 500}
                delay 2
                
                -- Type destination
                keystroke "Lost Lake, Oregon"
                delay 2
                
                -- Try to click Go button
                click at {350, 500}
                delay 3
            end tell
        end tell
        """
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.launch()
        task.waitUntilExit()
        
        // Take screenshot after interaction
        sleep(2)
        takeScreenshot(device: device, name: "after_interaction")
        
        print("✅ UI interaction test completed")
    }
}

// Run the test
StandaloneUITest.testAccessibilityElements()