#!/usr/bin/env node

/**
 * Agent Registry Manager MCP Tool
 * 
 * Manages and monitors the Claude Code agent registry to ensure all agents 
 * in .claude/agents/ are properly formatted and available through the Task tool.
 * 
 * Features:
 * - Validates agent YAML front matter format
 * - Fixes missing YAML headers automatically  
 * - Monitors agent availability through Task tool
 * - Provides registry diagnostics and repair functions
 * - Prevents agent registration issues
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ErrorCode, McpError } = require('@modelcontextprotocol/sdk/types.js');
import fs from 'fs';
const fsPromises = fsPromises;
import path from 'path';
import { execSync } from 'child_process';

class AgentRegistryManager {
  constructor() {
    this.server = new Server(
      {
        name: 'agent-registry-manager',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );
    
    this.agentsDir = path.join(process.cwd(), '.claude', 'agents');
    this.setupToolHandlers();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      switch (request.params.name) {
        case 'scan_agents':
          return this.scanAgents();
        case 'validate_agent_format':
          return this.validateAgentFormat(request.params.arguments);
        case 'fix_agent_format':
          return this.fixAgentFormat(request.params.arguments);
        case 'get_agent_status':
          return this.getAgentStatus();
        case 'repair_registry':
          return this.repairRegistry();
        case 'list_available_agents':
          return this.listAvailableAgents();
        default:
          throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${request.params.name}`);
      }
    });
  }

  /**
   * Scans all agent files in .claude/agents and validates their format
   */
  async scanAgents() {
    try {
      const files = await fs.readdir(this.agentsDir);
      const agentFiles = files.filter(file => file.startsWith('spec-') && file.endsWith('.md'));
      
      const results = {
        totalAgents: agentFiles.length,
        validAgents: [],
        invalidAgents: [],
        missingYaml: []
      };

      for (const file of agentFiles) {
        const filePath = path.join(this.agentsDir, file);
        const content = await fs.readFile(filePath, 'utf8');
        const agentName = file.replace('.md', '');
        
        const validation = this.validateYamlFrontMatter(content, agentName);
        
        if (validation.isValid) {
          results.validAgents.push({
            name: agentName,
            file: file,
            description: validation.description
          });
        } else {
          results.invalidAgents.push({
            name: agentName,
            file: file,
            issues: validation.issues
          });
          
          if (validation.issues.includes('missing_yaml')) {
            results.missingYaml.push(agentName);
          }
        }
      }

      return {
        content: [
          {
            type: 'text',
            text: `Agent Registry Scan Results:
            
📊 **Summary:**
- Total agents: ${results.totalAgents}
- Valid agents: ${results.validAgents.length}
- Invalid agents: ${results.invalidAgents.length}
- Missing YAML: ${results.missingYaml.length}

✅ **Valid Agents (${results.validAgents.length}):**
${results.validAgents.map(a => `- ${a.name}`).join('\n')}

❌ **Invalid Agents (${results.invalidAgents.length}):**
${results.invalidAgents.map(a => `- ${a.name}: ${a.issues.join(', ')}`).join('\n')}

🔧 **Agents needing YAML fix:**
${results.missingYaml.map(name => `- ${name}`).join('\n')}

Use 'fix_agent_format' tool to repair invalid agents automatically.`
          }
        ]
      };
    } catch (error) {
      throw new McpError(ErrorCode.InternalError, `Failed to scan agents: ${error.message}`);
    }
  }

  /**
   * Validates if an agent file has proper YAML front matter
   */
  validateYamlFrontMatter(content, expectedName) {
    const result = {
      isValid: true,
      issues: [],
      description: null
    };

    // Check if starts with YAML front matter
    if (!content.startsWith('---\n')) {
      result.isValid = false;
      result.issues.push('missing_yaml');
      return result;
    }

    // Extract YAML front matter
    const yamlEndIndex = content.indexOf('\n---\n', 4);
    if (yamlEndIndex === -1) {
      result.isValid = false;
      result.issues.push('incomplete_yaml');
      return result;
    }

    const yamlContent = content.substring(4, yamlEndIndex);
    const lines = yamlContent.split('\n');

    let hasName = false;
    let hasDescription = false;
    
    for (const line of lines) {
      if (line.startsWith('name: ')) {
        hasName = true;
        const name = line.substring(6).trim();
        if (name !== expectedName) {
          result.isValid = false;
          result.issues.push(`name_mismatch: expected ${expectedName}, got ${name}`);
        }
      }
      
      if (line.startsWith('description: ')) {
        hasDescription = true;
        result.description = line.substring(13).trim();
      }
    }

    if (!hasName) {
      result.isValid = false;
      result.issues.push('missing_name');
    }

    if (!hasDescription) {
      result.isValid = false;
      result.issues.push('missing_description');
    }

    return result;
  }

  /**
   * Validates a specific agent format
   */
  async validateAgentFormat(args) {
    if (!args.agent_name) {
      throw new McpError(ErrorCode.InvalidParams, 'agent_name parameter required');
    }

    try {
      const filePath = path.join(this.agentsDir, `${args.agent_name}.md`);
      const content = await fs.readFile(filePath, 'utf8');
      const validation = this.validateYamlFrontMatter(content, args.agent_name);

      return {
        content: [
          {
            type: 'text',
            text: `Agent Format Validation for '${args.agent_name}':
            
Status: ${validation.isValid ? '✅ Valid' : '❌ Invalid'}
${validation.description ? `Description: ${validation.description}` : ''}
${validation.issues.length > 0 ? `Issues: ${validation.issues.join(', ')}` : 'No issues found'}

${validation.isValid ? 'Agent format is correct and should be available through Task tool.' : 'Agent needs format fixes. Use fix_agent_format tool to repair.'}`
          }
        ]
      };
    } catch (error) {
      throw new McpError(ErrorCode.InvalidParams, `Agent '${args.agent_name}' not found: ${error.message}`);
    }
  }

  /**
   * Fixes agent format by adding/correcting YAML front matter
   */
  async fixAgentFormat(args) {
    if (!args.agent_name) {
      throw new McpError(ErrorCode.InvalidParams, 'agent_name parameter required');
    }

    try {
      const filePath = path.join(this.agentsDir, `${args.agent_name}.md`);
      const content = await fs.readFile(filePath, 'utf8');
      
      // Check if agent needs fixing
      const validation = this.validateYamlFrontMatter(content, args.agent_name);
      if (validation.isValid) {
        return {
          content: [
            {
              type: 'text',
              text: `Agent '${args.agent_name}' already has valid format. No changes needed.`
            }
          ]
        };
      }

      // Extract description from old format or use default
      let description = 'Agent description';
      
      // Try to extract description from old header format
      const descMatch = content.match(/\*\*Description:\*\*\s*(.+)/);
      if (descMatch) {
        description = descMatch[1].trim();
      }
      
      // Remove old header if present
      let newContent = content;
      if (content.includes('# ') && content.includes('**Name:**')) {
        const firstHeadingEnd = content.indexOf('\n---\n');
        if (firstHeadingEnd !== -1) {
          newContent = content.substring(firstHeadingEnd + 5);
        }
      }

      // Add YAML front matter
      const yamlHeader = `---
name: ${args.agent_name}
description: ${description}
---

`;

      const fixedContent = yamlHeader + newContent.replace(/^---\n[\s\S]*?\n---\n\n?/, '');

      // Create backup
      const backupPath = `${filePath}.backup`;
      await fs.copyFile(filePath, backupPath);

      // Write fixed content
      await fs.writeFile(filePath, fixedContent);

      return {
        content: [
          {
            type: 'text',
            text: `✅ Fixed agent format for '${args.agent_name}'
            
Changes made:
- Added YAML front matter with name and description
- Preserved original content
- Created backup at ${args.agent_name}.md.backup

The agent should now be available through the Task tool after Claude Code restart.`
          }
        ]
      };
    } catch (error) {
      throw new McpError(ErrorCode.InternalError, `Failed to fix agent format: ${error.message}`);
    }
  }

  /**
   * Gets overall agent status and availability
   */
  async getAgentStatus() {
    try {
      const scanResult = await this.scanAgents();
      const content = scanResult.content[0].text;
      
      return {
        content: [
          {
            type: 'text',
            text: `🔍 **Agent Registry Status Report**

${content}

💡 **Troubleshooting Tips:**
- If agents have valid YAML but aren't available: Restart Claude Code
- Agent changes require system reload to take effect
- Use 'repair_registry' tool to fix all agents at once
- Check Claude Code logs if issues persist

🛠️ **Available Commands:**
- scan_agents: Full registry scan
- fix_agent_format: Fix specific agent
- repair_registry: Fix all agents automatically
- list_available_agents: Test Task tool availability`
          }
        ]
      };
    } catch (error) {
      throw new McpError(ErrorCode.InternalError, `Failed to get agent status: ${error.message}`);
    }
  }

  /**
   * Repairs all agents with format issues
   */
  async repairRegistry() {
    try {
      const files = await fs.readdir(this.agentsDir);
      const agentFiles = files.filter(file => file.startsWith('spec-') && file.endsWith('.md'));
      
      const results = {
        totalAgents: agentFiles.length,
        fixedAgents: [],
        skippedAgents: [],
        errors: []
      };

      for (const file of agentFiles) {
        const agentName = file.replace('.md', '');
        try {
          const filePath = path.join(this.agentsDir, file);
          const content = await fs.readFile(filePath, 'utf8');
          
          const validation = this.validateYamlFrontMatter(content, agentName);
          if (!validation.isValid) {
            // Fix this agent
            const fixResult = await this.fixAgentFormat({ agent_name: agentName });
            results.fixedAgents.push(agentName);
          } else {
            results.skippedAgents.push(agentName);
          }
        } catch (error) {
          results.errors.push(`${agentName}: ${error.message}`);
        }
      }

      return {
        content: [
          {
            type: 'text',
            text: `🔧 **Agent Registry Repair Complete**
            
📊 **Results:**
- Total agents processed: ${results.totalAgents}
- Agents fixed: ${results.fixedAgents.length}
- Agents skipped (already valid): ${results.skippedAgents.length}  
- Errors: ${results.errors.length}

✅ **Fixed Agents (${results.fixedAgents.length}):**
${results.fixedAgents.map(name => `- ${name}`).join('\n')}

⏭️ **Skipped Agents (${results.skippedAgents.length}):**
${results.skippedAgents.map(name => `- ${name}`).join('\n')}

${results.errors.length > 0 ? `❌ **Errors:**\n${results.errors.map(err => `- ${err}`).join('\n')}` : ''}

🚀 **Next Steps:**
Restart Claude Code to ensure all agents are available through the Task tool.`
          }
        ]
      };
    } catch (error) {
      throw new McpError(ErrorCode.InternalError, `Failed to repair registry: ${error.message}`);
    }
  }

  /**
   * Lists agents that should be available (diagnostic tool)
   */
  async listAvailableAgents() {
    try {
      const files = await fs.readdir(this.agentsDir);
      const agentFiles = files.filter(file => file.startsWith('spec-') && file.endsWith('.md'));
      
      const agents = [];
      for (const file of agentFiles) {
        const agentName = file.replace('.md', '');
        const filePath = path.join(this.agentsDir, file);
        const content = await fs.readFile(filePath, 'utf8');
        
        const validation = this.validateYamlFrontMatter(content, agentName);
        agents.push({
          name: agentName,
          valid: validation.isValid,
          description: validation.description || 'No description',
          issues: validation.issues
        });
      }

      const validAgents = agents.filter(a => a.valid);
      const invalidAgents = agents.filter(a => !a.valid);

      return {
        content: [
          {
            type: 'text',
            text: `📋 **Agent Availability Report**

**Should be available through Task tool (${validAgents.length}):**
${validAgents.map(a => `- ${a.name}: ${a.description.substring(0, 80)}...`).join('\n')}

**Not available due to format issues (${invalidAgents.length}):**
${invalidAgents.map(a => `- ${a.name}: ${a.issues.join(', ')}`).join('\n')}

**Total agents in registry:** ${agents.length}

Use 'repair_registry' to fix all format issues automatically.`
          }
        ]
      };
    } catch (error) {
      throw new McpError(ErrorCode.InternalError, `Failed to list agents: ${error.message}`);
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Agent Registry Manager MCP server running on stdio');
  }
}

const server = new AgentRegistryManager();
server.run().catch(console.error);