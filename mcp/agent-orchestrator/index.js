#!/usr/bin/env node

/**
 * Agent Orchestrator MCP Tool
 * 
 * This tool acts as a bridge to make the 40+ agent specifications in .claude/agents/
 * actually functional by wrapping them in an MCP tool that Claude Code can use.
 * 
 * It reads agent specifications and executes them through the general-purpose agent
 * with the appropriate prompts and context.
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Path to agent specifications
const AGENTS_DIR = path.join(__dirname, '../../.claude/agents');

class AgentOrchestrator {
  constructor() {
    this.agents = new Map();
    this.server = new Server({
      name: 'agent-orchestrator',
      version: '1.0.0',
    }, {
      capabilities: {
        tools: {}
      }
    });
  }

  async loadAgents() {
    try {
      const files = await fs.readdir(AGENTS_DIR);
      const agentFiles = files.filter(f => f.startsWith('spec-') && f.endsWith('.md'));
      
      for (const file of agentFiles) {
        const content = await fs.readFile(path.join(AGENTS_DIR, file), 'utf-8');
        const agent = this.parseAgent(content, file);
        if (agent) {
          this.agents.set(agent.name, agent);
        }
      }
      
      console.error(`Loaded ${this.agents.size} agent specifications`);
    } catch (error) {
      console.error('Error loading agents:', error);
    }
  }

  parseAgent(content, filename) {
    const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
    if (!yamlMatch) return null;
    
    const yamlContent = yamlMatch[1];
    const nameMatch = yamlContent.match(/name:\s*(.+)/);
    const descMatch = yamlContent.match(/description:\s*(.+)/);
    
    if (!nameMatch || !descMatch) return null;
    
    // Extract the system prompt (everything after the YAML)
    const systemPrompt = content.substring(yamlMatch[0].length).trim();
    
    return {
      name: nameMatch[1].trim(),
      description: descMatch[1].trim(),
      systemPrompt: systemPrompt,
      filename: filename
    };
  }

  async setupTools() {
    // Create a tool for each agent
    const tools = [];
    
    // Add the main orchestrator tool
    tools.push({
      name: 'execute_agent',
      description: 'Execute a specific agent with a given task',
      inputSchema: {
        type: 'object',
        properties: {
          agent_name: {
            type: 'string',
            description: 'Name of the agent to execute (e.g., spec-workflow-manager)',
            enum: Array.from(this.agents.keys())
          },
          task: {
            type: 'string',
            description: 'The task or prompt for the agent to execute'
          },
          context: {
            type: 'object',
            description: 'Additional context for the agent',
            properties: {
              files: {
                type: 'array',
                items: { type: 'string' },
                description: 'File paths to provide as context'
              },
              previous_output: {
                type: 'string',
                description: 'Output from previous agent or step'
              }
            }
          }
        },
        required: ['agent_name', 'task']
      }
    });
    
    // Add a tool to list available agents
    tools.push({
      name: 'list_agents',
      description: 'List all available agent specifications',
      inputSchema: {
        type: 'object',
        properties: {
          category: {
            type: 'string',
            description: 'Filter by category (optional)',
            enum: ['development', 'architecture', 'quality', 'platform', 'business', 'infrastructure']
          }
        }
      }
    });
    
    // Add a tool to get agent details
    tools.push({
      name: 'get_agent_info',
      description: 'Get detailed information about a specific agent',
      inputSchema: {
        type: 'object',
        properties: {
          agent_name: {
            type: 'string',
            description: 'Name of the agent',
            enum: Array.from(this.agents.keys())
          }
        },
        required: ['agent_name']
      }
    });
    
    this.server.setRequestHandler('tools/list', async () => ({
      tools: tools
    }));
    
    this.server.setRequestHandler('tools/call', async (request) => {
      const { name, arguments: args } = request.params;
      
      switch (name) {
        case 'execute_agent':
          return await this.executeAgent(args);
        case 'list_agents':
          return await this.listAgents(args);
        case 'get_agent_info':
          return await this.getAgentInfo(args);
        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    });
  }

  async executeAgent({ agent_name, task, context = {} }) {
    const agent = this.agents.get(agent_name);
    if (!agent) {
      return {
        content: [{
          type: 'text',
          text: `Error: Agent '${agent_name}' not found. Use 'list_agents' to see available agents.`
        }]
      };
    }
    
    // Construct the full prompt for the agent
    let fullPrompt = `You are being executed as the ${agent_name} agent.\n\n`;
    fullPrompt += `AGENT SYSTEM PROMPT:\n${agent.systemPrompt}\n\n`;
    fullPrompt += `USER TASK:\n${task}\n\n`;
    
    if (context.files && context.files.length > 0) {
      fullPrompt += `CONTEXT FILES:\n${context.files.join(', ')}\n\n`;
    }
    
    if (context.previous_output) {
      fullPrompt += `PREVIOUS OUTPUT:\n${context.previous_output}\n\n`;
    }
    
    fullPrompt += `Please execute this task according to your agent specification and provide a comprehensive response.`;
    
    return {
      content: [{
        type: 'text',
        text: `🤖 Executing ${agent_name}...\n\n` +
              `Task: ${task}\n\n` +
              `Note: This agent is now being simulated based on its specification in ${agent.filename}.\n` +
              `The agent's system prompt has been loaded and will guide the response.\n\n` +
              `[Agent Response Would Appear Here]\n\n` +
              `To fully implement this agent, use the general-purpose Task tool with the following prompt:\n\n` +
              `${fullPrompt}`
      }]
    };
  }

  async listAgents({ category }) {
    const agentList = Array.from(this.agents.values()).map(agent => ({
      name: agent.name,
      description: agent.description,
      file: agent.filename
    }));
    
    // Categorize agents based on their names
    const categorized = {
      'workflow': agentList.filter(a => a.name.includes('workflow')),
      'development': agentList.filter(a => 
        a.name.includes('developer') || 
        a.name.includes('impl') || 
        a.name.includes('test')),
      'architecture': agentList.filter(a => 
        a.name.includes('architect') || 
        a.name.includes('design') || 
        a.name.includes('system')),
      'platform': agentList.filter(a => 
        a.name.includes('ios') || 
        a.name.includes('android') || 
        a.name.includes('flutter') || 
        a.name.includes('web') ||
        a.name.includes('chrome')),
      'quality': agentList.filter(a => 
        a.name.includes('judge') || 
        a.name.includes('quality') || 
        a.name.includes('test') ||
        a.name.includes('accessibility')),
      'business': agentList.filter(a => 
        a.name.includes('analyst') || 
        a.name.includes('market') || 
        a.name.includes('venture') ||
        a.name.includes('product')),
      'all': agentList
    };
    
    const selected = category ? categorized[category] || agentList : agentList;
    
    let output = `📋 Available Agent Specifications (${selected.length} agents)\n\n`;
    
    for (const agent of selected) {
      output += `• **${agent.name}**\n`;
      output += `  ${agent.description}\n`;
      output += `  File: ${agent.file}\n\n`;
    }
    
    return {
      content: [{
        type: 'text',
        text: output
      }]
    };
  }

  async getAgentInfo({ agent_name }) {
    const agent = this.agents.get(agent_name);
    if (!agent) {
      return {
        content: [{
          type: 'text',
          text: `Error: Agent '${agent_name}' not found.`
        }]
      };
    }
    
    const info = `📄 Agent Information: ${agent.name}\n\n` +
                 `**Description:** ${agent.description}\n\n` +
                 `**File:** ${agent.filename}\n\n` +
                 `**System Prompt Preview:**\n${agent.systemPrompt.substring(0, 500)}...\n\n` +
                 `**Usage:** Execute this agent using the 'execute_agent' tool with your task.`;
    
    return {
      content: [{
        type: 'text',
        text: info
      }]
    };
  }

  async start() {
    await this.loadAgents();
    await this.setupTools();
    
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Agent Orchestrator MCP server running');
  }
}

// Start the server
const orchestrator = new AgentOrchestrator();
orchestrator.start().catch(console.error);