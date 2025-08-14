#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
import { execSync } from 'child_process';

/**
 * iOS Project Manager - Automates Xcode project file management and builds
 * 
 * Usage:
 *   node ios-project-manager add-file <file-path> [group-name]
 *   node ios-project-manager build [scheme] [sdk]
 *   node ios-project-manager clean
 *   node ios-project-manager verify
 * 
 * Examples:
 *   node ios-project-manager add-file Views/NewView.swift Views
 *   node ios-project-manager build RoadtripCopilot iphonesimulator
 *   node ios-project-manager verify
 */

const PROJECT_ROOT = path.resolve(__dirname, '../../mobile/ios');
const PBXPROJ_PATH = path.join(PROJECT_ROOT, 'RoadtripCopilot.xcodeproj/project.pbxproj');

// Generate a unique 24-character UUID for Xcode project files
function generateXcodeUUID() {
    return require('crypto').randomBytes(12).toString('hex').toUpperCase();
}

// Parse command line arguments
const command = process.argv[2];
const args = process.argv.slice(3);

switch (command) {
    case 'add-file':
        addFileToProject(args[0], args[1]);
        break;
    case 'build':
        buildProject(args[0], args[1]);
        break;
    case 'clean':
        cleanProject();
        break;
    case 'verify':
        verifyProject();
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

function addFileToProject(filePath, groupName = 'Views') {
    if (!filePath) {
        console.error('Error: File path is required');
        process.exit(1);
    }

    console.log(`📁 Adding ${filePath} to iOS project...`);

    try {
        // Read the project file
        const projectContent = fs.readFileSync(PBXPROJ_PATH, 'utf8');
        
        // Generate UUIDs
        const fileRefUUID = generateXcodeUUID();
        const buildFileUUID = generateXcodeUUID();
        
        // Extract filename from path
        const fileName = path.basename(filePath);
        const fileExtension = path.extname(fileName);
        
        // Determine file type based on extension
        const fileType = getFileType(fileExtension);
        
        console.log(`   📄 File: ${fileName}`);
        console.log(`   🆔 File Reference UUID: ${fileRefUUID}`);
        console.log(`   🆔 Build File UUID: ${buildFileUUID}`);
        
        let updatedContent = projectContent;
        
        // 1. Add PBXBuildFile entry
        const buildFileEntry = `\t\t${buildFileUUID} /* ${fileName} in Sources */ = {isa = PBXBuildFile; fileRef = ${fileRefUUID} /* ${fileName} */; };`;
        updatedContent = addToBuildFileSection(updatedContent, buildFileEntry);
        
        // 2. Add PBXFileReference entry
        const fileRefEntry = `\t\t${fileRefUUID} /* ${fileName} */ = {isa = PBXFileReference; lastKnownFileType = ${fileType}; path = ${fileName}; sourceTree = "<group>"; };`;
        updatedContent = addToFileReferenceSection(updatedContent, fileRefEntry);
        
        // 3. Add to group (folder structure)
        updatedContent = addToGroup(updatedContent, fileRefUUID, fileName, groupName);
        
        // 4. Add to build phase if it's a source file
        if (fileExtension === '.swift' || fileExtension === '.m') {
            updatedContent = addToBuildPhase(updatedContent, buildFileUUID, fileName);
        }
        
        // Write the updated project file
        fs.writeFileSync(PBXPROJ_PATH, updatedContent);
        
        console.log(`✅ Successfully added ${fileName} to Xcode project`);
        console.log(`   📂 Group: ${groupName}`);
        console.log(`   🔨 Build Phase: ${fileExtension === '.swift' || fileExtension === '.m' ? 'Added' : 'Skipped'}`);
        
    } catch (error) {
        console.error('❌ Error adding file to project:', error.message);
        process.exit(1);
    }
}

function buildProject(scheme = 'RoadtripCopilot', sdk = 'iphonesimulator') {
    console.log(`🔨 Building iOS project (${scheme} for ${sdk})...`);
    
    try {
        const buildCommand = `cd "${PROJECT_ROOT}" && xcodebuild -scheme ${scheme} -sdk ${sdk} -configuration Debug build`;
        const output = execSync(buildCommand, { encoding: 'utf8', stdio: 'pipe' });
        
        // Parse build output for both lowercase and uppercase warnings
        const warnings = (output.match(/(warning:|WARNING:)/gi) || []).length;
        const errors = (output.match(/(error:|ERROR:)/gi) || []).length;
        
        // Always return the full output so mobile-build-verifier can parse warnings
        console.log(output);
        
        if (errors > 0) {
            console.log('❌ Build FAILED');
            console.log(`   🐛 Errors: ${errors}`);
            console.log(`   ⚠️  Warnings: ${warnings}`);
            
            // Show actual errors
            const errorLines = output.split('\\n').filter(line => 
                line.includes('error:') || line.includes('** BUILD FAILED **')
            );
            if (errorLines.length > 0) {
                console.log('\\n📋 Build Errors:');
                errorLines.slice(0, 10).forEach(line => console.log(`   ${line.trim()}`));
                if (errorLines.length > 10) {
                    console.log(`   ... and ${errorLines.length - 10} more errors`);
                }
            }
            process.exit(1);
        } else {
            console.log('✅ Build SUCCESSFUL');
            if (warnings > 0) {
                console.log(`   ⚠️  Warnings: ${warnings} (consider reviewing)`);
            }
        }
        
    } catch (error) {
        console.error('❌ Build failed:', error.message);
        // Parse stderr for specific errors
        if (error.stderr) {
            console.log('\\n📋 Error Details:');
            console.log(error.stderr);
        }
        process.exit(1);
    }
}

function cleanProject() {
    console.log('🧹 Cleaning iOS project...');
    
    try {
        const cleanCommand = `cd "${PROJECT_ROOT}" && xcodebuild clean`;
        execSync(cleanCommand, { stdio: 'inherit' });
        console.log('✅ Project cleaned successfully');
    } catch (error) {
        console.error('❌ Clean failed:', error.message);
        process.exit(1);
    }
}

function verifyProject() {
    console.log('🔍 Verifying iOS project integrity...');
    
    // Check if project file exists and is valid
    if (!fs.existsSync(PBXPROJ_PATH)) {
        console.error('❌ project.pbxproj file not found');
        process.exit(1);
    }
    
    try {
        const projectContent = fs.readFileSync(PBXPROJ_PATH, 'utf8');
        
        // Basic validation
        const requiredSections = [
            'Begin PBXBuildFile section',
            'Begin PBXFileReference section',
            'Begin PBXGroup section',
            'Begin PBXSourcesBuildPhase section'
        ];
        
        let isValid = true;
        requiredSections.forEach(section => {
            if (!projectContent.includes(section)) {
                console.error(`❌ Missing section: ${section}`);
                isValid = false;
            }
        });
        
        if (isValid) {
            console.log('✅ Project file is valid');
            
            // Count files
            const swiftFiles = (projectContent.match(/\\.swift/g) || []).length;
            const buildFiles = (projectContent.match(/in Sources/g) || []).length;
            
            console.log(`   📄 Swift files: ${swiftFiles}`);
            console.log(`   🔨 Build files: ${buildFiles}`);
        }
        
    } catch (error) {
        console.error('❌ Error verifying project:', error.message);
        process.exit(1);
    }
}

// Helper functions
function getFileType(extension) {
    const fileTypes = {
        '.swift': 'sourcecode.swift',
        '.m': 'sourcecode.c.objc',
        '.h': 'sourcecode.c.h',
        '.plist': 'text.plist.xml',
        '.json': 'text.json',
        '.txt': 'text'
    };
    return fileTypes[extension] || 'text';
}

function addToBuildFileSection(content, entry) {
    const buildFileMarker = '/* Begin PBXBuildFile section */';
    const insertPoint = content.indexOf(buildFileMarker) + buildFileMarker.length;
    return content.slice(0, insertPoint) + '\n' + entry + content.slice(insertPoint);
}

function addToFileReferenceSection(content, entry) {
    // Find a good place to insert in PBXFileReference section
    const marker = '/* Begin PBXFileReference section */';
    const endMarker = '/* End PBXFileReference section */';
    const startIndex = content.indexOf(marker);
    const endIndex = content.indexOf(endMarker);
    
    if (startIndex === -1 || endIndex === -1) {
        throw new Error('Could not find PBXFileReference section');
    }
    
    // Insert before the end marker
    return content.slice(0, endIndex) + entry + '\n\t\t' + content.slice(endIndex);
}

function addToGroup(content, fileRefUUID, fileName, groupName) {
    // Find the group section for the specified group
    const groupPattern = new RegExp(`([A-F0-9]{24})\\s*/\\*\\s*${groupName}\\s*\\*/\\s*=\\s*\\{[^}]*children\\s*=\\s*\\([^\\)]*\\)`, 'g');
    
    return content.replace(groupPattern, (match) => {
        // Insert the new file reference before the closing parenthesis
        return match.replace(/\)$/, `\t\t\t\t${fileRefUUID} /* ${fileName} */,\n\t\t\t);`);
    });
}

function addToBuildPhase(content, buildFileUUID, fileName) {
    // Find PBXSourcesBuildPhase and add the build file using simple string manipulation
    const buildPhaseMarker = "Begin PBXSourcesBuildPhase section";
    const filesMarker = "files = (";
    const endMarker = ");\n\t\t};";
    
    // Find the build phase section
    const buildPhaseStart = content.indexOf(buildPhaseMarker);
    if (buildPhaseStart === -1) return content;
    
    // Find files array within the build phase
    const filesStart = content.indexOf(filesMarker, buildPhaseStart);
    if (filesStart === -1) return content;
    
    // Find end of files array
    const filesEnd = content.indexOf(endMarker, filesStart);
    if (filesEnd === -1) return content;
    
    // Insert new build file entry
    const newEntry = `\t\t\t\t${buildFileUUID} /* ${fileName} in Sources */,\n\t\t\t`;
    return content.slice(0, filesEnd) + newEntry + content.slice(filesEnd);
}
function showHelp() {
    console.log(`
📱 iOS Project Manager

COMMANDS:
  add-file <path> [group]    Add a new file to the Xcode project
  build [scheme] [sdk]       Build the iOS project
  clean                      Clean the project build artifacts
  verify                     Verify project file integrity
  help                       Show this help message

EXAMPLES:
  node ios-project-manager add-file Views/NewView.swift Views
  node ios-project-manager build RoadtripCopilot iphonesimulator
  node ios-project-manager clean
  node ios-project-manager verify

OPTIONS:
  [group]    Target group/folder (default: Views)
  [scheme]   Xcode scheme name (default: RoadtripCopilot)
  [sdk]      Target SDK (default: iphonesimulator)
`);
}