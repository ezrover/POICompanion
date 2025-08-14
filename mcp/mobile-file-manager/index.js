#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
import { execSync } from 'child_process';

/**
 * Cross-Platform Mobile File Manager
 * 
 * Coordinates iOS and Android development for feature parity
 * 
 * Usage:
 *   node mobile-file-manager add-view <name> [description]
 *   node mobile-file-manager add-manager <name> [description]  
 *   node mobile-file-manager build-all
 *   node mobile-file-manager sync-check
 *   node mobile-file-manager feature-parity
 * 
 * Examples:
 *   node mobile-file-manager add-view LocationAuthorizationView "Location permission gate"
 *   node mobile-file-manager add-manager NotificationManager "Push notification handling"
 *   node mobile-file-manager build-all
 */

const PROJECT_ROOT = path.resolve(__dirname, '../..');
const IOS_MANAGER = path.join(__dirname, '../ios-project-manager/index.js');
const ANDROID_MANAGER = path.join(__dirname, '../android-project-manager/index.js');

// Parse command line arguments
const command = process.argv[2];
const args = process.argv.slice(3);

switch (command) {
    case 'add-view':
        addCrossPlatformView(args[0], args[1]);
        break;
    case 'add-manager':
        addCrossPlatformManager(args[0], args[1]);
        break;
    case 'build-all':
        buildAllPlatforms();
        break;
    case 'sync-check':
        checkPlatformSync();
        break;
    case 'feature-parity':
        checkFeatureParity();
        break;
    case 'help':
    case '--help':
    case '-h':
        showHelp();
        break;
    default:
        console.error('Unknown command:', command);
        showHelp();
        process.exit(1);
}

function addCrossPlatformView(viewName, description = '') {
    if (!viewName) {
        console.error('Error: View name is required');
        process.exit(1);
    }

    console.log(`🔄 Adding cross-platform view: ${viewName}`);
    if (description) {
        console.log(`   📝 Description: ${description}`);
    }

    try {
        // Add to iOS
        console.log('\\n📱 Adding to iOS project...');
        const iosFileName = `${viewName}.swift`;
        const iosResult = execSync(`node "${IOS_MANAGER}" add-file Views/${iosFileName} Views`, { 
            encoding: 'utf8', 
            stdio: 'pipe' 
        });
        console.log('   ✅ iOS: Added successfully');

        // Add to Android  
        console.log('\\n🤖 Adding to Android project...');
        const androidFileName = `${viewName.replace('View', 'Screen')}.kt`;
        const androidResult = execSync(`node "${ANDROID_MANAGER}" add-file ${androidFileName} ui.screens`, { 
            encoding: 'utf8',
            stdio: 'pipe' 
        });
        console.log('   ✅ Android: Added successfully');

        // Create implementation notes
        createImplementationNotes(viewName, 'View', description);

        console.log(`\\n✅ Cross-platform view ${viewName} added successfully!`);
        console.log(`   📄 iOS: Views/${iosFileName}`);
        console.log(`   📄 Android: ui/screens/${androidFileName}`);

    } catch (error) {
        console.error('❌ Error adding cross-platform view:', error.message);
        process.exit(1);
    }
}

function addCrossPlatformManager(managerName, description = '') {
    if (!managerName) {
        console.error('Error: Manager name is required');
        process.exit(1);
    }

    console.log(`🔄 Adding cross-platform manager: ${managerName}`);
    if (description) {
        console.log(`   📝 Description: ${description}`);
    }

    try {
        // Add to iOS
        console.log('\\n📱 Adding to iOS project...');
        const iosFileName = `${managerName}.swift`;
        const iosResult = execSync(`node "${IOS_MANAGER}" add-file Managers/${iosFileName} Managers`, { 
            encoding: 'utf8',
            stdio: 'pipe' 
        });
        console.log('   ✅ iOS: Added successfully');

        // Add to Android
        console.log('\\n🤖 Adding to Android project...');
        const androidFileName = `${managerName}.kt`;
        const androidResult = execSync(`node "${ANDROID_MANAGER}" add-file ${androidFileName} managers`, { 
            encoding: 'utf8',
            stdio: 'pipe' 
        });
        console.log('   ✅ Android: Added successfully');

        // Create implementation notes
        createImplementationNotes(managerName, 'Manager', description);

        console.log(`\\n✅ Cross-platform manager ${managerName} added successfully!`);
        console.log(`   📄 iOS: Managers/${iosFileName}`);
        console.log(`   📄 Android: managers/${androidFileName}`);

    } catch (error) {
        console.error('❌ Error adding cross-platform manager:', error.message);
        process.exit(1);
    }
}

function buildAllPlatforms() {
    console.log('🔨 Building all platforms...');
    
    let iosSuccess = false;
    let androidSuccess = false;

    // Build iOS
    console.log('\\n📱 Building iOS...');
    try {
        const iosResult = execSync(`node "${IOS_MANAGER}" build`, { 
            encoding: 'utf8', 
            stdio: 'pipe' 
        });
        console.log('   ✅ iOS build successful');
        iosSuccess = true;
    } catch (error) {
        console.log('   ❌ iOS build failed');
        console.log('   📋 iOS Error:', error.message.split('\\n')[0]);
    }

    // Build Android
    console.log('\\n🤖 Building Android...');
    try {
        const androidResult = execSync(`node "${ANDROID_MANAGER}" build`, { 
            encoding: 'utf8',
            stdio: 'pipe' 
        });
        console.log('   ✅ Android build successful');
        androidSuccess = true;
    } catch (error) {
        console.log('   ❌ Android build failed');
        console.log('   📋 Android Error:', error.message.split('\\n')[0]);
    }

    // Summary
    console.log('\\n📊 Build Summary:');
    console.log(`   iOS: ${iosSuccess ? '✅ SUCCESS' : '❌ FAILED'}`);
    console.log(`   Android: ${androidSuccess ? '✅ SUCCESS' : '❌ FAILED'}`);
    
    if (iosSuccess && androidSuccess) {
        console.log('\\n🎉 All platforms built successfully!');
    } else {
        console.log('\\n⚠️  Some builds failed. Check individual platform errors above.');
        process.exit(1);
    }
}

function checkPlatformSync() {
    console.log('🔍 Checking platform synchronization...');

    const iosPath = path.join(PROJECT_ROOT, 'mobile/ios/RoadtripCopilot');
    const androidPath = path.join(PROJECT_ROOT, 'mobile/android/app/src/main/java/com/roadtrip/copilot');

    // Check Views/Screens sync
    console.log('\\n📱 Views/Screens Analysis:');
    const iosViews = getFilesInDirectory(path.join(iosPath, 'Views'), '.swift');
    const androidScreens = getFilesInDirectory(path.join(androidPath, 'ui/screens'), '.kt');
    
    console.log(`   iOS Views: ${iosViews.length} files`);
    console.log(`   Android Screens: ${androidScreens.length} files`);
    
    // Check Managers sync
    console.log('\\n🔧 Managers Analysis:');
    const iosManagers = getFilesInDirectory(path.join(iosPath, 'Managers'), '.swift');
    const androidManagers = getFilesInDirectory(path.join(androidPath, 'managers'), '.kt');
    
    console.log(`   iOS Managers: ${iosManagers.length} files`);
    console.log(`   Android Managers: ${androidManagers.length} files`);

    // Feature parity suggestions
    console.log('\\n💡 Sync Recommendations:');
    if (Math.abs(iosViews.length - androidScreens.length) > 2) {
        console.log(`   ⚠️  View/Screen count mismatch (${iosViews.length} vs ${androidScreens.length})`);
    } else {
        console.log('   ✅ View/Screen counts are reasonably synchronized');
    }
    
    if (Math.abs(iosManagers.length - androidManagers.length) > 1) {
        console.log(`   ⚠️  Manager count mismatch (${iosManagers.length} vs ${androidManagers.length})`);
    } else {
        console.log('   ✅ Manager counts are well synchronized');
    }
}

function checkFeatureParity() {
    console.log('🎯 Analyzing feature parity...');

    // Define expected feature pairs
    const expectedFeatures = [
        { ios: 'LocationAuthorizationView.swift', android: 'LocationAuthorizationScreen.kt', feature: 'Location Permission Gate' },
        { ios: 'LocationManager.swift', android: 'LocationManager.kt', feature: 'Location Management' },
        { ios: 'SpeechManager.swift', android: 'SpeechManager.kt', feature: 'Speech Recognition' },
        { ios: 'WeatherManager.swift', android: 'WeatherManager.kt', feature: 'Weather Integration' }
    ];

    const iosPath = path.join(PROJECT_ROOT, 'mobile/ios/RoadtripCopilot');
    const androidPath = path.join(PROJECT_ROOT, 'mobile/android/app/src/main/java/com/roadtrip/copilot');

    let featuresChecked = 0;
    let featuresPaired = 0;

    console.log('\\n📊 Feature Parity Analysis:');

    expectedFeatures.forEach(feature => {
        featuresChecked++;
        
        const iosExists = fileExistsInProject(iosPath, feature.ios);
        const androidExists = fileExistsInProject(androidPath, feature.android);
        
        if (iosExists && androidExists) {
            console.log(`   ✅ ${feature.feature}: Both platforms implemented`);
            featuresPaired++;
        } else if (iosExists && !androidExists) {
            console.log(`   ⚠️  ${feature.feature}: iOS only (missing Android)`);
        } else if (!iosExists && androidExists) {
            console.log(`   ⚠️  ${feature.feature}: Android only (missing iOS)`);
        } else {
            console.log(`   ❌ ${feature.feature}: Missing on both platforms`);
        }
    });

    const parityPercentage = Math.round((featuresPaired / featuresChecked) * 100);
    
    console.log(`\\n📈 Feature Parity Score: ${parityPercentage}% (${featuresPaired}/${featuresChecked})`);
    
    if (parityPercentage >= 90) {
        console.log('   🎉 Excellent feature parity!');
    } else if (parityPercentage >= 70) {
        console.log('   👍 Good feature parity');
    } else {
        console.log('   ⚠️  Feature parity needs attention');
    }
}

// Helper functions
function createImplementationNotes(name, type, description) {
    const notesPath = path.join(PROJECT_ROOT, '.claude/implementation-notes');
    
    if (!fs.existsSync(notesPath)) {
        fs.mkdirSync(notesPath, { recursive: true });
    }
    
    const notesFile = path.join(notesPath, `${name}-implementation.md`);
    const timestamp = new Date().toISOString().split('T')[0];
    
    const notes = `# ${name} Implementation Notes

**Type**: ${type}
**Created**: ${timestamp}
${description ? `**Description**: ${description}\\n` : ''}

## Implementation Checklist

### iOS (Swift)
- [ ] Basic implementation structure
- [ ] SwiftUI integration (if view)
- [ ] iOS-specific features
- [ ] CarPlay integration (if applicable)
- [ ] Testing implementation

### Android (Kotlin)  
- [ ] Basic implementation structure
- [ ] Jetpack Compose integration (if screen)
- [ ] Android-specific features
- [ ] Android Auto integration (if applicable)
- [ ] Testing implementation

### Cross-Platform
- [ ] Feature parity verification
- [ ] Consistent API/interface
- [ ] Shared business logic alignment
- [ ] Testing on both platforms

## Notes
- Add implementation-specific notes here
- Document any platform differences
- Record testing results

---
*Auto-generated by Mobile File Manager*
`;

    fs.writeFileSync(notesFile, notes);
    console.log(`   📝 Implementation notes: ${notesFile}`);
}

function getFilesInDirectory(dirPath, extension) {
    if (!fs.existsSync(dirPath)) return [];
    
    return fs.readdirSync(dirPath)
        .filter(file => file.endsWith(extension))
        .map(file => path.basename(file, extension));
}

function fileExistsInProject(basePath, fileName) {
    // Search recursively for the file
    function searchFile(dir, target) {
        if (!fs.existsSync(dir)) return false;
        
        const files = fs.readdirSync(dir);
        for (const file of files) {
            const fullPath = path.join(dir, file);
            const stat = fs.statSync(fullPath);
            
            if (stat.isDirectory()) {
                if (searchFile(fullPath, target)) return true;
            } else if (file === target) {
                return true;
            }
        }
        return false;
    }
    
    return searchFile(basePath, fileName);
}

function showHelp() {
    console.log(`
🔄 Cross-Platform Mobile File Manager

Coordinates iOS and Android development for consistent feature implementation

COMMANDS:
  add-view <name> [desc]        Add UI component to both iOS and Android
  add-manager <name> [desc]     Add business logic manager to both platforms  
  build-all                     Build both iOS and Android projects
  sync-check                    Analyze platform synchronization
  feature-parity               Check feature implementation parity
  help                         Show this help message

EXAMPLES:
  node mobile-file-manager add-view LocationAuthorizationView "Location permission gate"
  node mobile-file-manager add-manager NotificationManager "Push notification handling"
  node mobile-file-manager build-all
  node mobile-file-manager sync-check
  node mobile-file-manager feature-parity

FEATURES:
  🎯 Cross-platform coordination    Ensures feature parity between iOS/Android
  📝 Implementation tracking        Auto-generates implementation checklists
  🔨 Unified build system          Builds and tests both platforms together
  📊 Sync analysis                  Monitors platform synchronization
  💡 Smart naming                   Converts View ↔ Screen naming automatically

NAMING CONVENTIONS:
  iOS                    Android                   Purpose
  ────────────────────────────────────────────────────────────
  LocationView.swift  →  LocationScreen.kt        UI Components
  DataManager.swift   →  DataManager.kt           Business Logic
  Utils.swift         →  Utils.kt                 Utilities

This tool ensures consistent cross-platform development and feature parity.
`);
}