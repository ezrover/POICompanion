# Agent Registry Manager MCP Tool

Manages and monitors the Claude Code agent registry to ensure all agents in `.claude/agents/` are properly formatted and available through the Task tool.

## Features

- **Agent Format Validation**: Validates YAML front matter format for all agents
- **Automatic Repair**: Fixes missing or incorrect YAML headers automatically  
- **Registry Monitoring**: Monitors agent availability through Task tool
- **Diagnostic Tools**: Provides comprehensive registry diagnostics
- **Bulk Operations**: Process all agents at once
- **Backup Safety**: Creates backups before making changes

## Available Tools

### `scan_agents`
Scans all agent files and validates their format
- Returns summary of valid/invalid agents
- Identifies agents needing YAML fixes
- No parameters required

### `validate_agent_format`
Validates a specific agent's format
- **Parameters**: `agent_name` (string) - Name of agent to validate
- Returns detailed validation results

### `fix_agent_format` 
Fixes a specific agent's YAML format
- **Parameters**: `agent_name` (string) - Name of agent to fix
- Creates backup before making changes
- Preserves original content while adding proper YAML

### `get_agent_status`
Gets overall agent registry status and troubleshooting tips
- Comprehensive status report
- Troubleshooting guidance
- Available command reference

### `repair_registry`
Repairs all agents with format issues in bulk
- Fixes all invalid agents automatically
- Creates backups for safety
- Detailed results summary

### `list_available_agents`
Lists all agents and their availability status
- Diagnostic tool for troubleshooting
- Shows which agents should be available
- Identifies format issues

## Required Agent Format

All agents must have YAML front matter:

```yaml
---
name: spec-agent-name
description: Agent description here
---
```

## Usage Examples

```javascript
// Scan all agents for issues
await mcp.callTool('scan_agents', {});

// Fix a specific agent
await mcp.callTool('fix_agent_format', { 
  agent_name: 'spec-security-sentinel' 
});

// Repair all agents at once
await mcp.callTool('repair_registry', {});

// Get status report
await mcp.callTool('get_agent_status', {});
```

## Troubleshooting

1. **Agents not appearing in Task tool**: 
   - Run `scan_agents` to check format
   - Use `repair_registry` to fix issues
   - Restart Claude Code after repairs

2. **Format validation fails**:
   - Check YAML syntax with `validate_agent_format`
   - Use `fix_agent_format` to repair automatically

3. **Bulk operations needed**:
   - Use `repair_registry` for all agents at once
   - Check results with `get_agent_status`

## Installation

The tool is automatically configured in `.claude/settings.local.json`. No additional installation required.