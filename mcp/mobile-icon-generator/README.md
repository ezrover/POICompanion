# Mobile Icon Generator

Converts SVG files to all required mobile app icon sizes for iOS and Android platforms.

## Features

- **SVG to PNG Conversion**: High-quality conversion using qlmanage or sips
- **iOS Icon Generation**: Creates all 17 required iOS app icon sizes (20px-1024px)
- **Android Icon Generation**: Creates all 15 required Android icon sizes across density buckets
- **Automatic Contents.json**: Generates proper iOS Assets.xcassets configuration
- **Adaptive Icons**: Supports Android adaptive icon foreground layers
- **Quality Assurance**: Built-in validation and error reporting

## Usage

### Command Line Interface

```bash
# Basic usage - generate both iOS and Android icons
node mobile-icon-generator/index.js /path/to/logo.svg

# With options
node mobile-icon-generator/index.js logo.svg --verbose --ios-project MyApp

# Skip platforms
node mobile-icon-generator/index.js logo.svg --no-ios
node mobile-icon-generator/index.js logo.svg --no-android
```

### As Node.js Module

```javascript
const { MobileIconGenerator } = require('./mobile-icon-generator');

const generator = new MobileIconGenerator({ verbose: true });
const results = await generator.generateFromSVG('logo.svg', {
    iosProject: 'MyApp',
    ios: true,
    android: true
});

console.log(`Generated ${results.summary.totalGenerated} icons`);
```

## Options

- `--ios-project <name>`: Specify iOS project name (default: RoadtripCopilot)
- `--no-ios`: Skip iOS icon generation
- `--no-android`: Skip Android icon generation
- `--verbose`: Enable detailed logging

## Generated iOS Icons

| Size | Filename | Usage |
|------|----------|-------|
| 40x40 | AppIcon-20@2x.png | iPhone Settings |
| 60x60 | AppIcon-20@3x.png | iPhone Settings |
| 58x58 | AppIcon-29@2x.png | iPhone Spotlight |
| 87x87 | AppIcon-29@3x.png | iPhone Spotlight |
| 80x80 | AppIcon-40@2x.png | iPhone Spotlight |
| 120x120 | AppIcon-40@3x.png | iPhone Spotlight |
| 120x120 | AppIcon-60@2x.png | iPhone App |
| 180x180 | AppIcon-60@3x.png | iPhone App |
| 20x20 | AppIcon-20@1x.png | iPad Settings |
| 40x40 | AppIcon-20@2x~ipad.png | iPad Settings |
| 29x29 | AppIcon-29@1x.png | iPad Settings |
| 58x58 | AppIcon-29@2x~ipad.png | iPad Settings |
| 40x40 | AppIcon-40@1x.png | iPad Spotlight |
| 80x80 | AppIcon-40@2x~ipad.png | iPad Spotlight |
| 152x152 | AppIcon-76@2x.png | iPad App |
| 167x167 | AppIcon-83.5@2x.png | iPad Pro |
| 1024x1024 | AppIcon-1024@1x.png | App Store |

## Generated Android Icons

### Standard Launcher Icons
- **mdpi**: 48x48px (ic_launcher.png, ic_launcher_round.png)
- **hdpi**: 72x72px (ic_launcher.png, ic_launcher_round.png)
- **xhdpi**: 96x96px (ic_launcher.png, ic_launcher_round.png)
- **xxhdpi**: 144x144px (ic_launcher.png, ic_launcher_round.png)
- **xxxhdpi**: 192x192px (ic_launcher.png, ic_launcher_round.png)

### Adaptive Icon Foreground Layers
- **mdpi**: 108x108px (ic_launcher_foreground.png)
- **hdpi**: 162x162px (ic_launcher_foreground.png)
- **xhdpi**: 216x216px (ic_launcher_foreground.png)
- **xxhdpi**: 324x324px (ic_launcher_foreground.png)
- **xxxhdpi**: 432x432px (ic_launcher_foreground.png)

## Project Structure Requirements

The tool expects the following project structure:

```
project-root/
├── mobile/
│   ├── ios/
│   │   └── ProjectName/
│   │       └── Assets.xcassets/
│   │           └── AppIcon.appiconset/
│   └── android/
│       └── app/
│           └── src/
│               └── main/
│                   └── res/
│                       ├── mipmap-mdpi/
│                       ├── mipmap-hdpi/
│                       ├── mipmap-xhdpi/
│                       ├── mipmap-xxhdpi/
│                       └── mipmap-xxxhdpi/
```

## Output Format

The tool returns a detailed results object:

```javascript
{
  ios: {
    success: true,
    icons: [
      { name: 'AppIcon-60@3x.png', size: 180, path: '/path/to/icon' }
    ],
    errors: []
  },
  android: {
    success: true,
    icons: [
      { name: 'ic_launcher.png', size: 192, density: 'xxxhdpi', path: '/path/to/icon' }
    ],
    errors: []
  },
  summary: {
    totalGenerated: 32,
    totalErrors: 0
  }
}
```

## Requirements

- **Node.js**: 14.0.0 or higher
- **macOS**: sips command-line tool (built-in)
- **SVG file**: Vector source file for icon generation

## Best Practices

1. **SVG Quality**: Use clean, simple vector graphics for best results
2. **Square Aspect**: Ensure SVG is square (1:1 aspect ratio)
3. **Scalability**: Design icons to be recognizable at small sizes (20px)
4. **Testing**: Use mobile-icon-verifier to validate generated icons
5. **Backup**: Keep original SVG files in version control

## Related Tools

- [mobile-icon-verifier](../mobile-icon-verifier/README.md): Verify generated icon quality
- [mobile-build-verifier](../mobile-build-verifier/README.md): Test app compilation