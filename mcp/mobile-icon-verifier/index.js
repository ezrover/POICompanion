#!/usr/bin/env node

import { exec } from 'child_process';
import fs from 'fs';
const fsPromises = fsPromises;
import path from 'path';

/**
 * Mobile Icon Verifier MCP Tool
 * Verifies mobile app icons for correctness, dimensions, and completeness
 */

const EXPECTED_IOS_ICONS = [
    { name: 'AppIcon-20@2x.png', expectedSize: { width: 40, height: 40 } },
    { name: 'AppIcon-20@3x.png', expectedSize: { width: 60, height: 60 } },
    { name: 'AppIcon-29@2x.png', expectedSize: { width: 58, height: 58 } },
    { name: 'AppIcon-29@3x.png', expectedSize: { width: 87, height: 87 } },
    { name: 'AppIcon-40@2x.png', expectedSize: { width: 80, height: 80 } },
    { name: 'AppIcon-40@3x.png', expectedSize: { width: 120, height: 120 } },
    { name: 'AppIcon-60@2x.png', expectedSize: { width: 120, height: 120 } },
    { name: 'AppIcon-60@3x.png', expectedSize: { width: 180, height: 180 } },
    { name: 'AppIcon-20@1x.png', expectedSize: { width: 20, height: 20 } },
    { name: 'AppIcon-20@2x~ipad.png', expectedSize: { width: 40, height: 40 } },
    { name: 'AppIcon-29@1x.png', expectedSize: { width: 29, height: 29 } },
    { name: 'AppIcon-29@2x~ipad.png', expectedSize: { width: 58, height: 58 } },
    { name: 'AppIcon-40@1x.png', expectedSize: { width: 40, height: 40 } },
    { name: 'AppIcon-40@2x~ipad.png', expectedSize: { width: 80, height: 80 } },
    { name: 'AppIcon-76@2x.png', expectedSize: { width: 152, height: 152 } },
    { name: 'AppIcon-83.5@2x.png', expectedSize: { width: 167, height: 167 } },
    { name: 'AppIcon-1024@1x.png', expectedSize: { width: 1024, height: 1024 } }
];

const EXPECTED_ANDROID_ICONS = [
    // Standard launcher icons
    { path: 'mipmap-mdpi/ic_launcher.png', expectedSize: { width: 48, height: 48 } },
    { path: 'mipmap-hdpi/ic_launcher.png', expectedSize: { width: 72, height: 72 } },
    { path: 'mipmap-xhdpi/ic_launcher.png', expectedSize: { width: 96, height: 96 } },
    { path: 'mipmap-xxhdpi/ic_launcher.png', expectedSize: { width: 144, height: 144 } },
    { path: 'mipmap-xxxhdpi/ic_launcher.png', expectedSize: { width: 192, height: 192 } },
    
    // Round launcher icons
    { path: 'mipmap-mdpi/ic_launcher_round.png', expectedSize: { width: 48, height: 48 } },
    { path: 'mipmap-hdpi/ic_launcher_round.png', expectedSize: { width: 72, height: 72 } },
    { path: 'mipmap-xhdpi/ic_launcher_round.png', expectedSize: { width: 96, height: 96 } },
    { path: 'mipmap-xxhdpi/ic_launcher_round.png', expectedSize: { width: 144, height: 144 } },
    { path: 'mipmap-xxxhdpi/ic_launcher_round.png', expectedSize: { width: 192, height: 192 } },
    
    // Foreground layer icons
    { path: 'mipmap-mdpi/ic_launcher_foreground.png', expectedSize: { width: 108, height: 108 } },
    { path: 'mipmap-hdpi/ic_launcher_foreground.png', expectedSize: { width: 162, height: 162 } },
    { path: 'mipmap-xhdpi/ic_launcher_foreground.png', expectedSize: { width: 216, height: 216 } },
    { path: 'mipmap-xxhdpi/ic_launcher_foreground.png', expectedSize: { width: 324, height: 324 } },
    { path: 'mipmap-xxxhdpi/ic_launcher_foreground.png', expectedSize: { width: 432, height: 432 } }
];

class MobileIconVerifier {
    constructor(options = {}) {
        this.projectRoot = options.projectRoot || process.cwd();
        this.iosPath = path.join(this.projectRoot, 'mobile/ios');
        this.androidPath = path.join(this.projectRoot, 'mobile/android/app/src/main/res');
        this.verbose = options.verbose || false;
    }

    async verifyAllIcons(options = {}) {
        const results = {
            ios: { valid: 0, invalid: 0, missing: 0, errors: [] },
            android: { valid: 0, invalid: 0, missing: 0, errors: [] },
            summary: { totalValid: 0, totalInvalid: 0, totalMissing: 0, overallScore: 0 }
        };

        try {
            // Verify iOS icons
            if (options.ios !== false) {
                const iosResult = await this.verifyIOSIcons(options.iosProject);
                results.ios = iosResult;
            }

            // Verify Android icons
            if (options.android !== false) {
                const androidResult = await this.verifyAndroidIcons();
                results.android = androidResult;
            }

            // Calculate summary
            results.summary.totalValid = results.ios.valid + results.android.valid;
            results.summary.totalInvalid = results.ios.invalid + results.android.invalid;
            results.summary.totalMissing = results.ios.missing + results.android.missing;
            
            const totalExpected = EXPECTED_IOS_ICONS.length + EXPECTED_ANDROID_ICONS.length;
            results.summary.overallScore = Math.round((results.summary.totalValid / totalExpected) * 100);

            this.log(`Verification complete: ${results.summary.totalValid} valid, ${results.summary.totalInvalid} invalid, ${results.summary.totalMissing} missing`);
            return results;

        } catch (error) {
            results.ios.errors.push(`Verification failed: ${error.message}`);
            results.android.errors.push(`Verification failed: ${error.message}`);
            return results;
        }
    }

    async verifyIOSIcons(projectName = 'RoadtripCopilot') {
        const result = { valid: 0, invalid: 0, missing: 0, errors: [] };

        try {
            const iconsetPath = path.join(this.iosPath, `${projectName}/Assets.xcassets/AppIcon.appiconset`);
            
            // Check if iconset directory exists
            try {
                await fs.access(iconsetPath);
            } catch (error) {
                result.errors.push(`iOS iconset directory not found: ${iconsetPath}`);
                result.missing = EXPECTED_IOS_ICONS.length;
                return result;
            }

            // Verify Contents.json
            const contentsPath = path.join(iconsetPath, 'Contents.json');
            try {
                await fs.access(contentsPath);
                const contents = JSON.parse(await fs.readFile(contentsPath, 'utf8'));
                this.log(`Contents.json found with ${contents.images?.length || 0} image entries`);
            } catch (error) {
                result.errors.push(`Contents.json missing or invalid: ${error.message}`);
            }

            // Verify each expected icon
            for (const iconConfig of EXPECTED_IOS_ICONS) {
                const iconPath = path.join(iconsetPath, iconConfig.name);
                
                try {
                    await fs.access(iconPath);
                    const dimensions = await this.getImageDimensions(iconPath);
                    
                    if (dimensions.width === iconConfig.expectedSize.width && 
                        dimensions.height === iconConfig.expectedSize.height) {
                        result.valid++;
                        this.log(`✓ ${iconConfig.name}: ${dimensions.width}x${dimensions.height} (correct)`);
                    } else {
                        result.invalid++;
                        result.errors.push(`${iconConfig.name}: Expected ${iconConfig.expectedSize.width}x${iconConfig.expectedSize.height}, got ${dimensions.width}x${dimensions.height}`);
                        this.log(`✗ ${iconConfig.name}: ${dimensions.width}x${dimensions.height} (incorrect)`);
                    }
                } catch (error) {
                    result.missing++;
                    result.errors.push(`${iconConfig.name}: Missing`);
                    this.log(`✗ ${iconConfig.name}: Missing`);
                }
            }

            return result;

        } catch (error) {
            result.errors.push(`iOS verification failed: ${error.message}`);
            return result;
        }
    }

    async verifyAndroidIcons() {
        const result = { valid: 0, invalid: 0, missing: 0, errors: [] };

        try {
            // Check if Android res directory exists
            try {
                await fs.access(this.androidPath);
            } catch (error) {
                result.errors.push(`Android res directory not found: ${this.androidPath}`);
                result.missing = EXPECTED_ANDROID_ICONS.length;
                return result;
            }

            // Verify each expected icon
            for (const iconConfig of EXPECTED_ANDROID_ICONS) {
                const iconPath = path.join(this.androidPath, iconConfig.path);
                
                try {
                    await fs.access(iconPath);
                    const dimensions = await this.getImageDimensions(iconPath);
                    
                    if (dimensions.width === iconConfig.expectedSize.width && 
                        dimensions.height === iconConfig.expectedSize.height) {
                        result.valid++;
                        this.log(`✓ ${iconConfig.path}: ${dimensions.width}x${dimensions.height} (correct)`);
                    } else {
                        result.invalid++;
                        result.errors.push(`${iconConfig.path}: Expected ${iconConfig.expectedSize.width}x${iconConfig.expectedSize.height}, got ${dimensions.width}x${dimensions.height}`);
                        this.log(`✗ ${iconConfig.path}: ${dimensions.width}x${dimensions.height} (incorrect)`);
                    }
                } catch (error) {
                    result.missing++;
                    result.errors.push(`${iconConfig.path}: Missing`);
                    this.log(`✗ ${iconConfig.path}: Missing`);
                }
            }

            return result;

        } catch (error) {
            result.errors.push(`Android verification failed: ${error.message}`);
            return result;
        }
    }

    async getImageDimensions(imagePath) {
        return new Promise((resolve, reject) => {
            const cmd = `sips -g pixelWidth -g pixelHeight "${imagePath}"`;
            exec(cmd, (error, stdout, stderr) => {
                if (error) {
                    reject(error);
                    return;
                }

                const lines = stdout.trim().split('\n');
                let width = 0, height = 0;

                for (const line of lines) {
                    if (line.includes('pixelWidth:')) {
                        width = parseInt(line.split(':')[1].trim());
                    } else if (line.includes('pixelHeight:')) {
                        height = parseInt(line.split(':')[1].trim());
                    }
                }

                if (width && height) {
                    resolve({ width, height });
                } else {
                    reject(new Error('Could not parse image dimensions'));
                }
            });
        });
    }

    async generateReport(results, outputPath) {
        const report = {
            timestamp: new Date().toISOString(),
            summary: results.summary,
            details: {
                ios: results.ios,
                android: results.android
            },
            recommendations: this.generateRecommendations(results)
        };

        if (outputPath) {
            await fs.writeFile(outputPath, JSON.stringify(report, null, 2));
            this.log(`Report saved to: ${outputPath}`);
        }

        return report;
    }

    generateRecommendations(results) {
        const recommendations = [];

        if (results.ios.missing > 0) {
            recommendations.push('Generate missing iOS icons using mobile-icon-generator tool');
        }
        if (results.android.missing > 0) {
            recommendations.push('Generate missing Android icons using mobile-icon-generator tool');
        }
        if (results.ios.invalid > 0) {
            recommendations.push('Regenerate invalid iOS icons with correct dimensions');
        }
        if (results.android.invalid > 0) {
            recommendations.push('Regenerate invalid Android icons with correct dimensions');
        }
        if (results.summary.overallScore === 100) {
            recommendations.push('All icons are valid and ready for deployment! 🎉');
        }

        return recommendations;
    }

    log(message) {
        if (this.verbose) {
            console.log(`[MobileIconVerifier] ${message}`);
        }
    }
}

// CLI interface
async function main() {
    const args = process.argv.slice(2);
    
    const options = {
        verbose: args.includes('--verbose'),
        ios: !args.includes('--no-ios'),
        android: !args.includes('--no-android')
    };

    const iosProjectIndex = args.indexOf('--ios-project');
    if (iosProjectIndex !== -1 && args[iosProjectIndex + 1]) {
        options.iosProject = args[iosProjectIndex + 1];
    }

    const reportIndex = args.indexOf('--report');
    const reportPath = reportIndex !== -1 && args[reportIndex + 1] ? args[reportIndex + 1] : null;

    const verifier = new MobileIconVerifier({ verbose: options.verbose });
    const results = await verifier.verifyAllIcons(options);

    // Generate report if requested
    if (reportPath) {
        await verifier.generateReport(results, path.resolve(reportPath));
    }

    // Output results
    console.log('\n=== Icon Verification Results ===');
    console.log(`Overall Score: ${results.summary.overallScore}%`);
    console.log(`Valid icons: ${results.summary.totalValid}`);
    console.log(`Invalid icons: ${results.summary.totalInvalid}`);
    console.log(`Missing icons: ${results.summary.totalMissing}`);
    
    if (results.ios.valid > 0 || results.ios.invalid > 0 || results.ios.missing > 0) {
        console.log(`\niOS: ${results.ios.valid} valid, ${results.ios.invalid} invalid, ${results.ios.missing} missing`);
        if (results.ios.errors.length > 0) {
            console.log('iOS Issues:');
            results.ios.errors.forEach(error => console.log(`  - ${error}`));
        }
    }
    
    if (results.android.valid > 0 || results.android.invalid > 0 || results.android.missing > 0) {
        console.log(`\nAndroid: ${results.android.valid} valid, ${results.android.invalid} invalid, ${results.android.missing} missing`);
        if (results.android.errors.length > 0) {
            console.log('Android Issues:');
            results.android.errors.forEach(error => console.log(`  - ${error}`));
        }
    }

    const recommendations = verifier.generateRecommendations(results);
    if (recommendations.length > 0) {
        console.log('\nRecommendations:');
        recommendations.forEach(rec => console.log(`  • ${rec}`));
    }

    process.exit(results.summary.totalInvalid > 0 || results.summary.totalMissing > 0 ? 1 : 0);
}

// Export for use as module
module.exports = { MobileIconVerifier };

// Run as CLI if called directly
if (require.main === module) {
    main().catch(console.error);
}