# MCP Tools Quick Reference

## Configuration Status: ✅ ACTIVE

Local MCP tools are configured in `.claude/settings.local.json` and ready for use.

## Available Tools

### 📱 Mobile Development
```bash
# Build verification
node mcp/mobile-build-verifier/index.js [ios|android]

# Test execution  
node mcp/mobile-test-runner/index.js

# Code linting
node mcp/mobile-linter/index.js
```

### 🔧 Development Tools
```bash
# Dependency management
node mcp/dependency-manager/index.js [command]

# Code generation
node mcp/code-generator/index.js [type] [options]

# Performance profiling
node mcp/performance-profiler/index.js [target]
```

### 🎨 Design & Quality
```bash
# Accessibility checking
node mcp/accessibility-checker/index.js [path]

# Design system management
node mcp/design-system-manager/index.js [command]
```

### 📋 Project Management
```bash
# Task management
node mcp/task-manager/index.js [add|list|update] [args]

# Specification generation
node mcp/spec-generator/index.js [type] [input]
```

## Integration Benefits

- **Reduced API Calls**: Local execution minimizes remote LLM requests
- **Faster Responses**: Direct tool execution without network latency  
- **Consistent Results**: Standardized tooling across development workflow
- **Cost Efficiency**: Lower token usage through automated task execution

## Self-Improvement Strategy

### BEFORE Every Task Implementation:
1. **EVALUATE**: Can existing MCP tools be enhanced for this task?
2. **CONSIDER**: Would a new MCP tool make this and future similar tasks faster?
3. **BUILD**: Create/improve tools that compound efficiency over time
4. **IMPLEMENT**: Use enhanced tools to complete the actual user request

### Usage Priority (NON-NEGOTIABLE):
1. **First**: Check if existing MCP tool can handle the task
2. **Second**: Improve existing tools to better handle the task  
3. **Third**: Create new MCP tool if beneficial for repeated use
4. **Fourth**: Enhance tools during task execution if patterns emerge
5. **Last**: Use generic Claude Code tools only for true one-off tasks

### Compound Benefits:
- **Week 1**: 10 tools → Save 20% API calls
- **Week 4**: 15 improved tools → Save 40% API calls  
- **Week 12**: 25 specialized tools → Save 70% API calls
- **Result**: Exponentially increasing efficiency and capability