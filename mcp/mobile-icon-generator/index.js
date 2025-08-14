#!/usr/bin/env node

const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

/**
 * Mobile Icon Generator MCP Tool
 * Converts SVG files to all required mobile app icon sizes for iOS and Android
 */

const IOS_ICON_SIZES = [
    // iPhone
    { name: 'AppIcon-20@2x.png', size: 40 },
    { name: 'AppIcon-20@3x.png', size: 60 },
    { name: 'AppIcon-29@2x.png', size: 58 },
    { name: 'AppIcon-29@3x.png', size: 87 },
    { name: 'AppIcon-40@2x.png', size: 80 },
    { name: 'AppIcon-40@3x.png', size: 120 },
    { name: 'AppIcon-60@2x.png', size: 120 },
    { name: 'AppIcon-60@3x.png', size: 180 },
    
    // iPad
    { name: 'AppIcon-20@1x.png', size: 20 },
    { name: 'AppIcon-20@2x~ipad.png', size: 40 },
    { name: 'AppIcon-29@1x.png', size: 29 },
    { name: 'AppIcon-29@2x~ipad.png', size: 58 },
    { name: 'AppIcon-40@1x.png', size: 40 },
    { name: 'AppIcon-40@2x~ipad.png', size: 80 },
    { name: 'AppIcon-76@2x.png', size: 152 },
    { name: 'AppIcon-83.5@2x.png', size: 167 },
    
    // App Store
    { name: 'AppIcon-1024@1x.png', size: 1024 }
];

const ANDROID_ICON_CONFIGS = [
    // Standard launcher icons
    { density: 'mdpi', size: 48, types: ['ic_launcher.png', 'ic_launcher_round.png'] },
    { density: 'hdpi', size: 72, types: ['ic_launcher.png', 'ic_launcher_round.png'] },
    { density: 'xhdpi', size: 96, types: ['ic_launcher.png', 'ic_launcher_round.png'] },
    { density: 'xxhdpi', size: 144, types: ['ic_launcher.png', 'ic_launcher_round.png'] },
    { density: 'xxxhdpi', size: 192, types: ['ic_launcher.png', 'ic_launcher_round.png'] },
    
    // Foreground layer for adaptive icons
    { density: 'mdpi', size: 108, types: ['ic_launcher_foreground.png'] },
    { density: 'hdpi', size: 162, types: ['ic_launcher_foreground.png'] },
    { density: 'xhdpi', size: 216, types: ['ic_launcher_foreground.png'] },
    { density: 'xxhdpi', size: 324, types: ['ic_launcher_foreground.png'] },
    { density: 'xxxhdpi', size: 432, types: ['ic_launcher_foreground.png'] }
];

const IOS_CONTENTS_JSON = {
    "images": [
        { "filename": "AppIcon-20@2x.png", "idiom": "iphone", "scale": "2x", "size": "20x20" },
        { "filename": "AppIcon-20@3x.png", "idiom": "iphone", "scale": "3x", "size": "20x20" },
        { "filename": "AppIcon-29@2x.png", "idiom": "iphone", "scale": "2x", "size": "29x29" },
        { "filename": "AppIcon-29@3x.png", "idiom": "iphone", "scale": "3x", "size": "29x29" },
        { "filename": "AppIcon-40@2x.png", "idiom": "iphone", "scale": "2x", "size": "40x40" },
        { "filename": "AppIcon-40@3x.png", "idiom": "iphone", "scale": "3x", "size": "40x40" },
        { "filename": "AppIcon-60@2x.png", "idiom": "iphone", "scale": "2x", "size": "60x60" },
        { "filename": "AppIcon-60@3x.png", "idiom": "iphone", "scale": "3x", "size": "60x60" },
        { "filename": "AppIcon-20@1x.png", "idiom": "ipad", "scale": "1x", "size": "20x20" },
        { "filename": "AppIcon-20@2x~ipad.png", "idiom": "ipad", "scale": "2x", "size": "20x20" },
        { "filename": "AppIcon-29@1x.png", "idiom": "ipad", "scale": "1x", "size": "29x29" },
        { "filename": "AppIcon-29@2x~ipad.png", "idiom": "ipad", "scale": "2x", "size": "29x29" },
        { "filename": "AppIcon-40@1x.png", "idiom": "ipad", "scale": "1x", "size": "40x40" },
        { "filename": "AppIcon-40@2x~ipad.png", "idiom": "ipad", "scale": "2x", "size": "40x40" },
        { "filename": "AppIcon-76@2x.png", "idiom": "ipad", "scale": "2x", "size": "76x76" },
        { "filename": "AppIcon-83.5@2x.png", "idiom": "ipad", "scale": "2x", "size": "83.5x83.5" },
        { "filename": "AppIcon-1024@1x.png", "idiom": "ios-marketing", "scale": "1x", "size": "1024x1024" }
    ],
    "info": { "author": "mcp-tool", "version": 1 }
};

class MobileIconGenerator {
    constructor(options = {}) {
        this.projectRoot = options.projectRoot || process.cwd();
        this.iosPath = path.join(this.projectRoot, 'mobile/ios');
        this.androidPath = path.join(this.projectRoot, 'mobile/android/app/src/main/res');
        this.verbose = options.verbose || false;
    }

    async generateFromSVG(svgPath, options = {}) {
        const results = {
            ios: { success: false, icons: [], errors: [] },
            android: { success: false, icons: [], errors: [] },
            summary: { totalGenerated: 0, totalErrors: 0 }
        };

        try {
            // Validate SVG file
            await fs.access(svgPath);
            this.log(`Starting icon generation from SVG: ${svgPath}`);

            // Generate intermediate PNG for better quality
            const tempPNG = path.join(path.dirname(svgPath), 'temp-1024.png');
            await this.convertSVGtoPNG(svgPath, tempPNG, 1024);

            // Generate iOS icons
            if (options.ios !== false) {
                const iosResult = await this.generateIOSIcons(tempPNG, options.iosProject);
                results.ios = iosResult;
                results.summary.totalGenerated += iosResult.icons.length;
                results.summary.totalErrors += iosResult.errors.length;
            }

            // Generate Android icons
            if (options.android !== false) {
                const androidResult = await this.generateAndroidIcons(tempPNG);
                results.android = androidResult;
                results.summary.totalGenerated += androidResult.icons.length;
                results.summary.totalErrors += androidResult.errors.length;
            }

            // Cleanup temp file
            await fs.unlink(tempPNG).catch(() => {});

            this.log(`Icon generation complete: ${results.summary.totalGenerated} icons generated, ${results.summary.totalErrors} errors`);
            return results;

        } catch (error) {
            results.summary.totalErrors++;
            results.ios.errors.push(`SVG processing failed: ${error.message}`);
            results.android.errors.push(`SVG processing failed: ${error.message}`);
            return results;
        }
    }

    async convertSVGtoPNG(svgPath, outputPath, size) {
        return new Promise((resolve, reject) => {
            // Use qlmanage for high-quality SVG to PNG conversion on macOS
            const cmd = `qlmanage -t -s ${size} -o "${path.dirname(outputPath)}" "${svgPath}" && mv "${path.dirname(outputPath)}/$(basename "${svgPath}").png" "${outputPath}"`;
            
            exec(cmd, (error, stdout, stderr) => {
                if (error) {
                    // Fallback to sips if available
                    const fallbackCmd = `sips -s format png -Z ${size} "${svgPath}" --out "${outputPath}"`;
                    exec(fallbackCmd, (fallbackError) => {
                        if (fallbackError) {
                            reject(new Error(`SVG conversion failed: ${error.message}`));
                        } else {
                            resolve();
                        }
                    });
                } else {
                    resolve();
                }
            });
        });
    }

    async generateIOSIcons(sourcePNG, projectName = 'RoadtripCopilot') {
        const result = { success: false, icons: [], errors: [] };
        
        try {
            const iconsetPath = path.join(this.iosPath, `${projectName}/Assets.xcassets/AppIcon.appiconset`);
            await fs.mkdir(iconsetPath, { recursive: true });

            // Generate all iOS icon sizes
            for (const iconConfig of IOS_ICON_SIZES) {
                try {
                    const outputPath = path.join(iconsetPath, iconConfig.name);
                    await this.resizeImage(sourcePNG, outputPath, iconConfig.size);
                    result.icons.push({ name: iconConfig.name, size: iconConfig.size, path: outputPath });
                    this.log(`Generated iOS icon: ${iconConfig.name} (${iconConfig.size}px)`);
                } catch (error) {
                    result.errors.push(`Failed to generate ${iconConfig.name}: ${error.message}`);
                }
            }

            // Generate Contents.json
            const contentsPath = path.join(iconsetPath, 'Contents.json');
            await fs.writeFile(contentsPath, JSON.stringify(IOS_CONTENTS_JSON, null, 2));
            this.log(`Generated Contents.json for iOS icons`);

            result.success = result.icons.length > 0;
            return result;

        } catch (error) {
            result.errors.push(`iOS icon generation failed: ${error.message}`);
            return result;
        }
    }

    async generateAndroidIcons(sourcePNG) {
        const result = { success: false, icons: [], errors: [] };

        try {
            for (const config of ANDROID_ICON_CONFIGS) {
                const densityDir = path.join(this.androidPath, `mipmap-${config.density}`);
                await fs.mkdir(densityDir, { recursive: true });

                for (const iconType of config.types) {
                    try {
                        const outputPath = path.join(densityDir, iconType);
                        await this.resizeImage(sourcePNG, outputPath, config.size);
                        result.icons.push({ 
                            name: iconType, 
                            size: config.size, 
                            density: config.density, 
                            path: outputPath 
                        });
                        this.log(`Generated Android icon: ${iconType} (${config.size}px) for ${config.density}`);
                    } catch (error) {
                        result.errors.push(`Failed to generate ${config.density}/${iconType}: ${error.message}`);
                    }
                }
            }

            result.success = result.icons.length > 0;
            return result;

        } catch (error) {
            result.errors.push(`Android icon generation failed: ${error.message}`);
            return result;
        }
    }

    async resizeImage(sourcePath, outputPath, size) {
        return new Promise((resolve, reject) => {
            const cmd = `sips -Z ${size} "${sourcePath}" --out "${outputPath}"`;
            exec(cmd, (error, stdout, stderr) => {
                if (error) {
                    reject(error);
                } else {
                    resolve();
                }
            });
        });
    }

    log(message) {
        if (this.verbose) {
            console.log(`[MobileIconGenerator] ${message}`);
        }
    }
}

// CLI interface
async function main() {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.log('Usage: mobile-icon-generator <svg-path> [options]');
        console.log('Options:');
        console.log('  --ios-project <name>  iOS project name (default: RoadtripCopilot)');
        console.log('  --no-ios             Skip iOS icon generation');
        console.log('  --no-android         Skip Android icon generation');
        console.log('  --verbose            Enable verbose logging');
        process.exit(1);
    }

    const svgPath = path.resolve(args[0]);
    const options = {
        verbose: args.includes('--verbose'),
        ios: !args.includes('--no-ios'),
        android: !args.includes('--no-android')
    };

    const iosProjectIndex = args.indexOf('--ios-project');
    if (iosProjectIndex !== -1 && args[iosProjectIndex + 1]) {
        options.iosProject = args[iosProjectIndex + 1];
    }

    const generator = new MobileIconGenerator({ verbose: options.verbose });
    const results = await generator.generateFromSVG(svgPath, options);

    // Output results
    console.log('\n=== Icon Generation Results ===');
    console.log(`Total icons generated: ${results.summary.totalGenerated}`);
    console.log(`Total errors: ${results.summary.totalErrors}`);
    
    if (results.ios.icons.length > 0) {
        console.log(`\niOS icons: ${results.ios.icons.length} generated`);
    }
    if (results.ios.errors.length > 0) {
        console.log(`iOS errors: ${results.ios.errors.join(', ')}`);
    }
    
    if (results.android.icons.length > 0) {
        console.log(`Android icons: ${results.android.icons.length} generated`);
    }
    if (results.android.errors.length > 0) {
        console.log(`Android errors: ${results.android.errors.join(', ')}`);
    }

    process.exit(results.summary.totalErrors > 0 ? 1 : 0);
}

// Export for use as module
module.exports = { MobileIconGenerator };

// Run as CLI if called directly
if (require.main === module) {
    main().catch(console.error);
}