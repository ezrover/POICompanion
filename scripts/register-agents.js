#!/usr/bin/env node

/**
 * Register Agents Script
 * 
 * This script creates a bridge to make the 40+ agent specifications functional
 * by generating wrapper scripts that Claude Code can execute through the Task tool.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const AGENTS_DIR = path.join(__dirname, '../.claude/agents');
const OUTPUT_FILE = path.join(__dirname, '../.claude/AGENT_REGISTRY.md');

function parseAgent(content, filename) {
  const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
  if (!yamlMatch) return null;
  
  const yamlContent = yamlMatch[1];
  const nameMatch = yamlContent.match(/name:\s*(.+)/);
  const descMatch = yamlContent.match(/description:\s*(.+)/);
  
  if (!nameMatch || !descMatch) return null;
  
  const systemPrompt = content.substring(yamlMatch[0].length).trim();
  
  return {
    name: nameMatch[1].trim(),
    description: descMatch[1].trim(),
    systemPrompt: systemPrompt,
    filename: filename
  };
}

async function main() {
  console.log('🔍 Scanning agent specifications...\n');
  
  const files = fs.readdirSync(AGENTS_DIR);
  const agentFiles = files.filter(f => f.startsWith('spec-') && f.endsWith('.md'));
  
  const agents = [];
  
  for (const file of agentFiles) {
    const content = fs.readFileSync(path.join(AGENTS_DIR, file), 'utf-8');
    const agent = parseAgent(content, file);
    if (agent) {
      agents.push(agent);
      console.log(`✅ Found agent: ${agent.name}`);
    }
  }
  
  console.log(`\n📊 Total agents found: ${agents.length}\n`);
  
  // Generate the registry document
  let registry = `# Agent Registry - ${agents.length} Agents Available\n\n`;
  registry += `Generated: ${new Date().toISOString()}\n\n`;
  registry += `## ⚠️ IMPORTANT: How to Use These Agents\n\n`;
  registry += `Since Claude Code's Task tool doesn't directly support custom agents, use the following workaround:\n\n`;
  registry += `1. Use the \`general-purpose\` agent via Task tool\n`;
  registry += `2. Include the agent's system prompt from this registry\n`;
  registry += `3. Prefix your task with the agent's role and instructions\n\n`;
  registry += `### Example Usage:\n\n`;
  registry += `\`\`\`javascript\n`;
  registry += `// To use spec-workflow-manager:\n`;
  registry += `Task tool with subagent_type: "general-purpose"\n`;
  registry += `Prompt: "Act as spec-workflow-manager. [Include system prompt]. Task: [Your task]"\n`;
  registry += `\`\`\`\n\n`;
  registry += `---\n\n`;
  
  // Categorize agents
  const categories = {
    'Workflow Management': agents.filter(a => a.name.includes('workflow')),
    'Development': agents.filter(a => 
      a.name.includes('developer') || 
      a.name.includes('impl') || 
      a.name.includes('test') ||
      a.name.includes('code')),
    'Architecture': agents.filter(a => 
      a.name.includes('architect') || 
      a.name.includes('design') || 
      a.name.includes('system')),
    'Platform-Specific': agents.filter(a => 
      a.name.includes('ios') || 
      a.name.includes('android') || 
      a.name.includes('flutter') || 
      a.name.includes('web') ||
      a.name.includes('chrome') ||
      a.name.includes('firmware')),
    'Quality & Testing': agents.filter(a => 
      a.name.includes('judge') || 
      a.name.includes('quality') || 
      a.name.includes('test') ||
      a.name.includes('accessibility')),
    'Business & Strategy': agents.filter(a => 
      a.name.includes('analyst') || 
      a.name.includes('market') || 
      a.name.includes('venture') ||
      a.name.includes('product') ||
      a.name.includes('customer') ||
      a.name.includes('partnership')),
    'Data & AI': agents.filter(a => 
      a.name.includes('data') || 
      a.name.includes('ai') || 
      a.name.includes('model') ||
      a.name.includes('scientist')),
    'Infrastructure': agents.filter(a => 
      a.name.includes('sre') || 
      a.name.includes('cloud') || 
      a.name.includes('database') ||
      a.name.includes('performance')),
    'Specialized': agents.filter(a => 
      a.name.includes('legal') || 
      a.name.includes('regulatory') || 
      a.name.includes('localization') ||
      a.name.includes('creator'))
  };
  
  // Write categorized agents
  for (const [category, categoryAgents] of Object.entries(categories)) {
    if (categoryAgents.length === 0) continue;
    
    registry += `## ${category} (${categoryAgents.length} agents)\n\n`;
    
    for (const agent of categoryAgents) {
      registry += `### ${agent.name}\n\n`;
      registry += `**Description:** ${agent.description}\n\n`;
      registry += `**File:** \`.claude/agents/${agent.filename}\`\n\n`;
      registry += `<details>\n`;
      registry += `<summary>System Prompt (click to expand)</summary>\n\n`;
      registry += `\`\`\`markdown\n`;
      registry += agent.systemPrompt.substring(0, 1000);
      if (agent.systemPrompt.length > 1000) {
        registry += '\n\n[... truncated for brevity - see full prompt in agent file ...]';
      }
      registry += `\n\`\`\`\n\n`;
      registry += `</details>\n\n`;
      registry += `---\n\n`;
    }
  }
  
  // Write the registry file
  fs.writeFileSync(OUTPUT_FILE, registry);
  console.log(`\n✅ Agent registry written to: ${OUTPUT_FILE}\n`);
  
  // Generate a wrapper function for CLAUDE.md
  const wrapper = `
## 🤖 Agent Execution Wrapper

Since the spec-* agents aren't directly available through Task tool, use this approach:

\`\`\`javascript
function executeSpecAgent(agentName, task) {
  // Read the agent's system prompt from .claude/agents/{agentName}.md
  // Use Task tool with general-purpose agent
  // Include the system prompt in the task description
  return Task({
    subagent_type: "general-purpose",
    prompt: \`
      You are executing as the \${agentName} agent.
      
      [Include agent system prompt here from registry]
      
      Task: \${task}
    \`
  });
}
\`\`\`
`;
  
  console.log('📝 Wrapper function for agent execution:');
  console.log(wrapper);
  
  console.log('\n🎯 Next Steps:');
  console.log('1. The agent specifications are now documented in AGENT_REGISTRY.md');
  console.log('2. Use the general-purpose agent with the system prompts to simulate each agent');
  console.log('3. Consider creating actual MCP tools for critical agents');
}

main().catch(console.error);