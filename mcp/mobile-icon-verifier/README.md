# Mobile Icon Verifier

Verifies mobile app icons for correctness, dimensions, and completeness across iOS and Android platforms.

## Features

- **Comprehensive Verification**: Checks all 32 required mobile app icons
- **Dimension Validation**: Ensures pixel-perfect dimensions for each icon size
- **Missing Icon Detection**: Identifies gaps in icon coverage
- **Quality Scoring**: Provides overall completeness score
- **Detailed Reporting**: Generates JSON reports with recommendations
- **Cross-Platform**: Supports both iOS and Android icon verification

## Usage

### Command Line Interface

```bash
# Basic verification
node mobile-icon-verifier/index.js

# With detailed logging
node mobile-icon-verifier/index.js --verbose

# Generate JSON report
node mobile-icon-verifier/index.js --report verification-report.json

# Verify specific platforms
node mobile-icon-verifier/index.js --no-android  # iOS only
node mobile-icon-verifier/index.js --no-ios      # Android only

# Custom iOS project name
node mobile-icon-verifier/index.js --ios-project MyApp
```

### As Node.js Module

```javascript
const { MobileIconVerifier } = require('./mobile-icon-verifier');

const verifier = new MobileIconVerifier({ verbose: true });
const results = await verifier.verifyAllIcons({
    iosProject: 'MyApp',
    ios: true,
    android: true
});

console.log(`Overall Score: ${results.summary.overallScore}%`);
console.log(`Valid: ${results.summary.totalValid}, Missing: ${results.summary.totalMissing}`);
```

## Output Format

### Console Output
```
=== Icon Verification Results ===
Overall Score: 100%
Valid icons: 32
Invalid icons: 0
Missing icons: 0

iOS: 17 valid, 0 invalid, 0 missing
Android: 15 valid, 0 invalid, 0 missing

Recommendations:
  • All icons are valid and ready for deployment! 🎉
```

### Programmatic Results
```javascript
{
  ios: {
    valid: 17,
    invalid: 0,
    missing: 0,
    errors: []
  },
  android: {
    valid: 15,
    invalid: 0,
    missing: 0,
    errors: []
  },
  summary: {
    totalValid: 32,
    totalInvalid: 0,
    totalMissing: 0,
    overallScore: 100
  }
}
```

## Verified Icon Specifications

### iOS Icons (17 total)

| Icon | Expected Size | Purpose |
|------|---------------|---------|
| AppIcon-20@2x.png | 40×40 | iPhone Settings |
| AppIcon-20@3x.png | 60×60 | iPhone Settings |
| AppIcon-29@2x.png | 58×58 | iPhone Spotlight |
| AppIcon-29@3x.png | 87×87 | iPhone Spotlight |
| AppIcon-40@2x.png | 80×80 | iPhone Spotlight |
| AppIcon-40@3x.png | 120×120 | iPhone Spotlight |
| AppIcon-60@2x.png | 120×120 | iPhone App |
| AppIcon-60@3x.png | 180×180 | iPhone App |
| AppIcon-20@1x.png | 20×20 | iPad Settings |
| AppIcon-20@2x~ipad.png | 40×40 | iPad Settings |
| AppIcon-29@1x.png | 29×29 | iPad Settings |
| AppIcon-29@2x~ipad.png | 58×58 | iPad Settings |
| AppIcon-40@1x.png | 40×40 | iPad Spotlight |
| AppIcon-40@2x~ipad.png | 80×80 | iPad Spotlight |
| AppIcon-76@2x.png | 152×152 | iPad App |
| AppIcon-83.5@2x.png | 167×167 | iPad Pro |
| AppIcon-1024@1x.png | 1024×1024 | App Store |

### Android Icons (15 total)

| Density | Standard | Round | Foreground |
|---------|----------|-------|------------|
| mdpi | 48×48 | 48×48 | 108×108 |
| hdpi | 72×72 | 72×72 | 162×162 |
| xhdpi | 96×96 | 96×96 | 216×216 |
| xxhdpi | 144×144 | 144×144 | 324×324 |
| xxxhdpi | 192×192 | 192×192 | 432×432 |

## Verification Process

1. **File Existence**: Checks if all required icon files exist
2. **Dimension Validation**: Uses sips to verify pixel dimensions
3. **Format Verification**: Ensures files are valid PNG images
4. **Contents.json Check**: Validates iOS iconset configuration
5. **Completeness Assessment**: Calculates overall coverage percentage

## Options

- `--verbose`: Enable detailed per-icon logging
- `--report <path>`: Generate detailed JSON report
- `--ios-project <name>`: Specify iOS project name (default: RoadtripCopilot)
- `--no-ios`: Skip iOS icon verification
- `--no-android`: Skip Android icon verification

## Report Generation

Generate detailed JSON reports for integration with CI/CD pipelines:

```bash
node mobile-icon-verifier/index.js --report icons-report.json
```

### Report Structure
```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "summary": {
    "totalValid": 32,
    "totalInvalid": 0,
    "totalMissing": 0,
    "overallScore": 100
  },
  "details": {
    "ios": { "valid": 17, "invalid": 0, "missing": 0, "errors": [] },
    "android": { "valid": 15, "invalid": 0, "missing": 0, "errors": [] }
  },
  "recommendations": [
    "All icons are valid and ready for deployment! 🎉"
  ]
}
```

## Common Issues & Solutions

### Missing Icons
```
Missing icons: 5
Recommendations:
  • Generate missing iOS icons using mobile-icon-generator tool
```

**Solution**: Run the mobile-icon-generator tool to create missing icons.

### Invalid Dimensions
```
iOS Issues:
  - AppIcon-60@3x.png: Expected 180x180, got 160x160
```

**Solution**: Regenerate icons with correct dimensions using mobile-icon-generator.

### iOS Contents.json Issues
```
iOS Issues:
  - Contents.json missing or invalid
```

**Solution**: The mobile-icon-generator tool automatically creates proper Contents.json files.

## Integration with CI/CD

### GitHub Actions Example
```yaml
- name: Verify App Icons
  run: |
    node mcp/mobile-icon-verifier/index.js --report icons-report.json
    if [ $? -eq 0 ]; then
      echo "✅ All icons verified successfully"
    else
      echo "❌ Icon verification failed"
      exit 1
    fi
```

### Pre-commit Hook
```bash
#!/bin/sh
# Verify icons before commit
node mcp/mobile-icon-verifier/index.js
exit $?
```

## Requirements

- **Node.js**: 14.0.0 or higher
- **macOS**: sips command-line tool (built-in)
- **Project Structure**: Standard iOS/Android mobile project layout

## Related Tools

- [mobile-icon-generator](../mobile-icon-generator/README.md): Generate missing icons
- [mobile-build-verifier](../mobile-build-verifier/README.md): Verify app compilation
- [mobile-test-runner](../mobile-test-runner/README.md): Run mobile app tests

## Exit Codes

- `0`: All icons verified successfully
- `1`: Invalid or missing icons detected

Perfect for automated quality assurance in mobile development workflows!