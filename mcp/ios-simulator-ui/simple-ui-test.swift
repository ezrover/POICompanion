#!/usr/bin/env swift

import Foundation

// Simple UI Test for testing iOS Simulator interaction
class SimpleUITest {
    static func main() {
        print("🧪 Starting simple UI test for Lost Lake, Oregon destination...")
        
        guard let deviceId = getBootedDevice() else {
            print("❌ No booted simulator found")
            return
        }
        
        print("📱 Using device: \(deviceId)")
        
        // Launch the app
        launchApp(device: deviceId)
        
        // Wait for app to load
        sleep(3)
        
        // Take initial screenshot
        takeScreenshot(device: deviceId, name: "01_initial_state")
        
        // Perform UI interaction
        performDestinationTest(device: deviceId)
        
        print("✅ Simple UI test completed")
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
    
    static func performDestinationTest(device: String) {
        print("🔍 Performing destination input test...")
        
        // Use AppleScript to interact with the UI
        let script = """
        tell application "Simulator"
            activate
        end tell
        
        delay 2
        
        tell application "System Events"
            tell process "Simulator"
                set frontmost to true
                delay 1
                
                -- Click on search field (adjusted coordinates for visible UI)
                click at {207, 480}
                delay 1
                
                -- Type Lost Lake, Oregon
                keystroke "Lost Lake, Oregon"
                delay 3
                
                -- Click Go button (right side of search area)
                click at {350, 480}
                delay 5
            end tell
        end tell
        """
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.launch()
        task.waitUntilExit()
        
        // Take screenshot after typing
        takeScreenshot(device: device, name: "02_after_typing")
        
        sleep(2)
        
        // Take final screenshot
        takeScreenshot(device: device, name: "03_after_navigation")
        
        print("✅ Destination test interaction completed")
    }
    
    static func runCommand(_ command: String, _ arguments: [String]) -> String? {
        let task = Process()
        task.launchPath = command
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}

// Run the test
SimpleUITest.main()