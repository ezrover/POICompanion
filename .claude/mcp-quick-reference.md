# MCP Tools Quick Reference

## Configuration Status: ✅ ACTIVE

All MCP tools are now unified into a single server configured in `.claude/settings.local.json`.

## Unified MCP Server Access

All tools are accessed through the unified POI Companion MCP server using the format:
```
mcp__poi-companion__[tool_name]
```

## Available Tools

### 📱 Mobile Development
```
# Build verification
mcp__poi-companion__mobile_build_verify
  - platform: 'ios' | 'android' | 'both'
  - clean: boolean (optional)
  - autoFix: boolean (optional)
  - detailed: boolean (optional)

# Test execution  
mcp__poi-companion__mobile_test_run
  - platform: 'ios' | 'android' | 'both'
  - suite: string (optional)
  - coverage: boolean (optional)

# E2E UI Testing
mcp__poi-companion__e2e_ui_test_run
  - platform: 'ios' | 'android' | 'both'
  - critical: boolean (optional)
  - skipBuild: boolean (optional)

# Linting
mcp__poi-companion__mobile_lint
  - platform: 'ios' | 'android' | 'both'
  - fix: boolean (optional)
```

### 🔧 Development Tools
```
# Code generation
mcp__poi-companion__code_generate
  - type: 'component' | 'test' | 'feature' | 'screen'
  - platform: 'ios' | 'android' | 'web' | 'cross-platform'
  - name: string
  - template: string (optional)

# Performance profiling
mcp__poi-companion__performance_profile
  - action: 'baseline' | 'monitor' | 'analyze' | 'report'
  - platform: 'ios' | 'android' | 'both'
  - duration: number (optional)

# Dependency management
mcp__poi-companion__dependency_manage
  - action: 'validate' | 'update' | 'check' | 'audit'
  - platform: 'ios' | 'android' | 'web' | 'all'
```

### 🎨 Design & Quality
```
# Accessibility checking
mcp__poi-companion__accessibility_check
  - action: 'scan' | 'test' | 'report' | 'watch'
  - standard: 'wcag-a' | 'wcag-aa' | 'wcag-aaa'
  - platform: 'ios' | 'android' | 'web' | 'all'

# Design system management
mcp__poi-companion__design_system_manage
  - action: 'validate' | 'generate' | 'sync' | 'audit'
  - component: string (optional)
  - platform: 'ios' | 'android' | 'web' | 'all'
```

### 📋 Project Management
```
# Task management
mcp__poi-companion__task_manage
  - action: 'create' | 'list' | 'update' | 'complete' | 'status'
  - task: string (optional)
  - priority: 'low' | 'medium' | 'high' | 'critical' (optional)

# Specification generation
mcp__poi-companion__spec_generate
  - type: 'requirements' | 'design' | 'api' | 'test'
  - feature: string
  - template: string (optional)

# Document processing
mcp__poi-companion__doc_process
  - action: 'analyze' | 'generate' | 'validate' | 'convert'
  - source: string (optional)
  - format: 'markdown' | 'html' | 'json' | 'pdf' (optional)
```

### 🤖 AI & Model Tools
```
# Model optimization
mcp__poi-companion__model_optimize
  - action: 'train' | 'optimize' | 'quantize' | 'benchmark'
  - model: string (optional)
  - platform: 'ios' | 'android' | 'both'

# Schema validation
mcp__poi-companion__schema_validate
  - action: 'validate' | 'generate' | 'check' | 'fix'
  - schema: string (optional)
  - data: string (optional)
```

### 🎯 Platform-Specific Tools
```
# Android project management
mcp__poi-companion__android_project_manage
  - action: 'init' | 'add-deps' | 'configure' | 'add-auto-support'
  - project: string (optional)
  - dependencies: array (optional)

# iOS project management
mcp__poi-companion__ios_project_manage
  - action: 'init' | 'add-deps' | 'configure' | 'add-carplay'
  - project: string (optional)
  - pods: array (optional)

# Icon generation
mcp__poi-companion__icon_generate
  - source: string
  - platform: 'ios' | 'android' | 'both'
  - adaptive: boolean (optional)

# Icon verification
mcp__poi-companion__icon_verify
  - platform: 'ios' | 'android' | 'both'
  - validateAll: boolean (optional)
```

### 🎭 Agent Orchestration
```
# Execute agent
mcp__poi-companion__execute_agent
  - agent_name: string
  - task: string
  - context: object (optional)

# List agents
mcp__poi-companion__list_agents
  - category: 'development' | 'architecture' | 'quality' | 'platform' | 'business' | 'infrastructure' (optional)

# Get agent info
mcp__poi-companion__get_agent_info
  - agent_name: string
```

### 📊 Quality & Testing Tools
```
# General test runner
mcp__poi-companion__test_run
  - framework: 'jest' | 'vitest' | 'junit' | 'xctest'
  - action: 'run' | 'watch' | 'coverage' | 'init'
  - path: string (optional)
  - coverage: boolean (optional)

# QA validation
mcp__poi-companion__qa_validate
  - platform: 'ios' | 'android' | 'both'
  - checks: array of 'ui' | 'performance' | 'security' | 'accessibility' | 'all'
  - strict: boolean (optional)
```

### 🏗️ Infrastructure Tools
```
# Build coordination
mcp__poi-companion__build_coordinate
  - action: 'build' | 'test' | 'deploy' | 'validate'
  - platforms: array of 'ios' | 'android' | 'web'
  - parallel: boolean (optional)

# Project scaffolding
mcp__poi-companion__project_scaffold
  - platform: 'ios' | 'android' | 'web' | 'flutter'
  - template: string (optional)
  - name: string (optional)
  - features: array (optional)

# File management
mcp__poi-companion__file_manage
  - action: 'scan' | 'organize' | 'clean' | 'analyze'
  - platform: 'ios' | 'android' | 'both'
  - path: string (optional)
```

### 🔄 Utility Tools
```
# UI generation
mcp__poi-companion__ui_generate
  - framework: 'react' | 'compose' | 'swiftui' | 'flutter'
  - component: string
  - template: string (optional)
  - screen: string (optional)

# Market analysis
mcp__poi-companion__market_analyze
  - action: 'research' | 'analyze' | 'compare' | 'trends'
  - competitor: string (optional)
  - market: string (optional)
  - region: string (optional)

# Agent registry management
mcp__poi-companion__agent_registry_manage
  - action: 'scan' | 'repair' | 'status' | 'update'
  - fix: boolean (optional)
```

## Usage Examples

### Through Claude Code Interface
When using Claude Code, these tools are accessible through the MCP interface. Claude will automatically use the appropriate tool based on the task.

### Direct Invocation Examples
```javascript
// Build both platforms
mcp__poi-companion__mobile_build_verify({
  platform: 'both',
  clean: true,
  autoFix: true
})

// Run E2E tests
mcp__poi-companion__e2e_ui_test_run({
  platform: 'ios',
  critical: true
})

// Generate a component
mcp__poi-companion__code_generate({
  type: 'component',
  platform: 'android',
  name: 'POIDetailCard'
})

// Execute an agent
mcp__poi-companion__execute_agent({
  agent_name: 'agent-android-developer',
  task: 'Implement voice recognition feature'
})
```

## Notes
- All tools are now unified into a single MCP server
- The server location is configured in `.claude/settings.local.json`
- Tools use the standardized `mcp__poi-companion__[tool_name]` format
- The unified server provides better performance and consistency