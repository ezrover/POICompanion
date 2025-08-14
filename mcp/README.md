# POI Companion MCP Server

A comprehensive Model Context Protocol (MCP) server providing 24+ specialized tools for mobile development, testing, performance optimization, and quality assurance for iOS/Android applications.

## Features

### 🚀 Mobile Development Tools
- **Mobile Build Verification**: iOS/Android builds with intelligent error analysis
- **Mobile Testing**: Comprehensive test execution with coverage reporting
- **Mobile Linting**: Code quality analysis and style enforcement
- **Android Emulator Testing**: Automated UI validation and performance monitoring
- **iOS Simulator Testing**: Accessibility validation and CarPlay testing

### 🔧 Code Quality & Architecture Tools
- **Code Generation**: Boilerplate code and component templates
- **Performance Profiling**: App performance analysis and optimization
- **Accessibility Checking**: WCAG compliance validation
- **Design System Management**: Component consistency and validation

### 📋 Project Management Tools
- **Task Management**: Structured development task tracking
- **Dependency Management**: Project dependencies and version control
- **Build Coordination**: Cross-platform build automation
- **Documentation Processing**: Document analysis and generation
- **Specification Generation**: Technical specification creation

## Installation

### Local Development

```bash
# Clone the repository
cd /path/to/POICompanion/mcp

# Install dependencies
npm install

# Build the server
npm run build

# Run the server
npm start
```

### Global Installation

```bash
# Install globally
npm install -g poi-companion-mcp-server

# Run with npx
npx poi-companion-mcp-server
```

## Configuration for Claude Desktop

Add to your Claude Desktop configuration (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "poi-companion": {
      "command": "npx",
      "args": ["poi-companion-mcp-server"]
    }
  }
}
```

Or for local development:

```json
{
  "mcpServers": {
    "poi-companion": {
      "command": "node",
      "args": ["/path/to/POICompanion/mcp/dist/index.js"]
    }
  }
}
```

## Available Tools

### Mobile Development

#### `mobile_build_verify`
Verify iOS/Android builds with intelligent error analysis and auto-fixes.

**Parameters:**
- `platform` (required): "ios", "android", or "both"
- `clean` (optional): Clean before building
- `autoFix` (optional): Attempt automatic fixes
- `detailed` (optional): Show detailed error analysis

**Example:**
```json
{
  "platform": "ios",
  "clean": true,
  "autoFix": true,
  "detailed": true
}
```

#### `mobile_test_run`
Execute comprehensive mobile app tests with detailed reporting.

**Parameters:**
- `platform` (required): "ios", "android", or "both"
- `testType` (optional): "unit", "integration", "ui", or "all"
- `coverage` (optional): Generate coverage report

#### `mobile_lint_check`
Code quality analysis and style enforcement for mobile projects.

**Parameters:**
- `platform` (required): "ios", "android", or "both"
- `autoFix` (optional): Automatically fix linting issues
- `severity` (optional): "error", "warning", or "all"

#### `android_emulator_test`
Automated Android emulator testing with UI validation.

**Parameters:**
- `action` (required): "lost-lake-test", "validate-components", "monitor-performance", "test-voice-interface"
- `duration` (optional): Duration for monitoring tests
- `command` (optional): Voice command to test

#### `ios_simulator_test`
Automated iOS simulator testing with accessibility validation.

**Parameters:**
- `action` (required): "lost-lake-test", "validate-buttons", "test-accessibility", "test-carplay"
- `voiceOver` (optional): Enable VoiceOver for accessibility testing
- `scenario` (optional): CarPlay scenario to test

### Code Quality & Architecture

#### `code_generate`
Generate boilerplate code and components from templates.

**Parameters:**
- `type` (required): "component", "test", "feature", "screen"
- `platform` (required): "ios", "android", "web", "cross-platform"
- `name` (required): Name of the component/feature
- `template` (optional): Specific template to use

#### `performance_profile`
Analyze app performance and provide optimization recommendations.

**Parameters:**
- `action` (required): "baseline", "monitor", "analyze", "report"
- `platform` (required): "ios", "android", "both"
- `duration` (optional): Monitoring duration in seconds

#### `accessibility_check`
Validate WCAG compliance and accessibility standards.

**Parameters:**
- `action` (required): "scan", "test", "report", "watch"
- `standard` (optional): "wcag-a", "wcag-aa", "wcag-aaa"
- `platform` (optional): "ios", "android", "web", "all"

#### `design_system_manage`
Manage design system components and consistency.

**Parameters:**
- `action` (required): "validate", "generate", "sync", "audit"
- `component` (optional): Specific component to manage
- `platform` (optional): "ios", "android", "web", "all"

### Project Management

#### `task_manage`
Structured development task management and tracking.

**Parameters:**
- `action` (required): "create", "list", "update", "complete", "status"
- `task` (optional): Task description or ID
- `priority` (optional): "low", "medium", "high", "critical"

#### `dependency_manage`
Project dependencies and version management.

**Parameters:**
- `action` (required): "validate", "update", "check", "audit"
- `platform` (optional): "ios", "android", "web", "all"

#### `build_coordinate`
Cross-platform build coordination and automation.

**Parameters:**
- `action` (required): "build", "test", "deploy", "validate"
- `platforms` (required): Array of platforms ["ios", "android", "web"]
- `parallel` (optional): Execute builds in parallel

#### `doc_process`
Document analysis and processing for implementation context.

**Parameters:**
- `action` (required): "analyze", "generate", "validate", "convert"
- `source` (optional): Source document or path
- `format` (optional): "markdown", "html", "json", "pdf"

#### `spec_generate`
Generate technical specifications from requirements.

**Parameters:**
- `type` (required): "requirements", "design", "api", "test"
- `feature` (required): Feature name or description
- `template` (optional): Template to use for generation

## Usage Examples

### Building iOS Project
```json
{
  "tool": "mobile_build_verify",
  "arguments": {
    "platform": "ios",
    "clean": true,
    "autoFix": true
  }
}
```

### Running Android Tests
```json
{
  "tool": "mobile_test_run",
  "arguments": {
    "platform": "android",
    "testType": "ui",
    "coverage": true
  }
}
```

### Testing Lost Lake Oregon Flow
```json
{
  "tool": "android_emulator_test",
  "arguments": {
    "action": "lost-lake-test"
  }
}
```

### Generating React Component
```json
{
  "tool": "code_generate",
  "arguments": {
    "type": "component",
    "platform": "web",
    "name": "POISearchForm",
    "template": "react-typescript"
  }
}
```

### Performance Monitoring
```json
{
  "tool": "performance_profile",
  "arguments": {
    "action": "monitor",
    "platform": "both",
    "duration": 120
  }
}
```

### Accessibility Validation
```json
{
  "tool": "accessibility_check",
  "arguments": {
    "action": "scan",
    "standard": "wcag-aa",
    "platform": "all"
  }
}
```

## Development

### Building

```bash
npm run build
```

### Running in Development Mode

```bash
npm run dev
```

### Testing

The server can be tested using the MCP CLI tools:

```bash
# Install MCP CLI
npm install -g @modelcontextprotocol/cli

# Test the server
mcp-cli test ./dist/index.js
```

## Architecture

The MCP server is built using TypeScript and the official MCP SDK. It provides a unified interface to all the existing POI Companion tools while maintaining backward compatibility.

### Key Components

- **Server Class**: Main MCP server implementation
- **Tool Handlers**: Individual tool execution logic
- **Error Handling**: Comprehensive error management
- **Type Safety**: Full TypeScript support with Zod validation

### Tool Integration

Each tool handler calls the corresponding legacy tool script while providing:
- Parameter validation
- Error handling
- Output formatting
- Timeout management
- Progress tracking

## Contributing

1. Add new tools by extending the `getToolDefinitions()` method
2. Implement the corresponding handler in `handleToolCall()`
3. Add appropriate error handling and validation
4. Update this README with tool documentation

## License

MIT License - see LICENSE file for details

## Support

For issues and feature requests, please use the GitHub issue tracker or refer to the project documentation.
-   [**market-analyzer**](./market-analyzer/README.md): Simulates fetching and analyzing market data based on a given query.
-   [**design-system-manager**](./design-system-manager/README.md): Manages and enforces design system consistency across the project.
-   [**task-manager**](./task-manager/README.md): Manages and tracks tasks in a structured way.
-   [**code-generator**](./code-generator/README.md): Generates boilerplate code for different components and services.
-   [**test-runner**](./test-runner/README.md): Provides a unified interface to run different types of tests.
-   [**performance-profiler**](./performance-profiler/README.md): Profiles code and identifies performance bottlenecks.
-   [**model-optimizer**](./model-optimizer/README.md): Optimizes AI models for different platforms and optimization types.
-   [**build-master**](./build-master/README.md): Automates the build and deployment process for different platforms.
-   [**dependency-manager**](./dependency-manager/README.md): Manages and updates dependencies across the project.
-   [**ui-generator**](./ui-generator/README.md): Generates UI components and mockups from a design specification.
-   [**accessibility-checker**](./accessibility-checker/README.md): Checks UI components or HTML files for WCAG compliance.
-   [**schema-validator**](./schema-validator/README.md): Validates data against a given JSON schema.
-   [**mobile-build-verifier**](./mobile-build-verifier/README.md): Automates local compilation checks for iOS and Android projects.
-   [**mobile-linter**](./mobile-linter/README.md): Runs project-specific linters and static analysis tools locally for mobile projects.
-   [**mobile-test-runner**](./mobile-test-runner/README.md): Executes unit, integration, and UI tests for both iOS and Android locally.
-   [**mobile-icon-generator**](./mobile-icon-generator/README.md): Converts SVG files to all required mobile app icon sizes for iOS and Android.
-   [**mobile-icon-verifier**](./mobile-icon-verifier/README.md): Verifies mobile app icons for correctness, dimensions, and completeness.
