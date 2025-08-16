#!/usr/bin/env node

/**
 * Create New Agent Script
 * 
 * This script creates a new agent specification when the current 40 agents
 * are inadequate for a task. It ensures proper format and registration.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import readline from 'readline';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const AGENTS_DIR = path.join(__dirname, '../.claude/agents');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (query) => new Promise((resolve) => rl.question(query, resolve));

async function createAgent() {
  console.log('🚀 NEW AGENT CREATION WIZARD\n');
  console.log('This wizard helps create new specialized agents when the current 40 are inadequate.\n');
  
  // Gather agent information
  const name = await question('Agent name (format: agent-domain-specialization): ');
  if (!name.startsWith('agent-')) {
    console.error('❌ Agent name must start with "agent-"');
    process.exit(1);
  }
  
  const description = await question('Short description (one line): ');
  const gap = await question('What gap does this fill in current workforce?: ');
  const expertise = await question('Primary expertise areas (comma-separated): ');
  const validation = await question('How will this agent validate/prove task completion?: ');
  const integration = await question('Which existing agents will it work with?: ');
  
  console.log('\n📝 Generating agent specification...\n');
  
  // Create the agent specification
  const agentSpec = `---
name: ${name}
description: ${description}
---

You are a specialized agent created to fill a specific gap in the AI workforce.

## Core Purpose
${gap}

## Primary Expertise
${expertise.split(',').map(e => `- ${e.trim()}`).join('\n')}

## Validation & Proof Methods
${validation}

## Integration with Existing Agents
${integration}

## Operational Guidelines

### Quality Standards
- Deliver enterprise-grade outputs exceeding industry standards
- Provide comprehensive documentation and validation
- Ensure reproducible and verifiable results
- Maintain consistency with other agents in the workforce

### Communication Protocol
- Clearly state capabilities and limitations upfront
- Provide step-by-step progress updates
- Document all decisions and rationale
- Deliver structured, actionable outputs

### Validation Requirements
- All outputs must be verifiable and testable
- Provide proof of correctness for critical operations
- Include validation metrics and success criteria
- Document edge cases and error handling

## Task Execution Framework

### Phase 1: Analysis
- Understand the task requirements completely
- Identify dependencies and prerequisites
- Assess feasibility and potential challenges
- Define success criteria and validation methods

### Phase 2: Planning
- Create detailed execution plan
- Identify required resources and tools
- Establish checkpoints and milestones
- Define rollback procedures if needed

### Phase 3: Implementation
- Execute task according to plan
- Document progress at each step
- Validate intermediate results
- Handle errors gracefully

### Phase 4: Validation
- Verify all success criteria are met
- Run comprehensive validation checks
- Document proof of completion
- Provide detailed report

## Output Format

### Standard Response Structure
1. **Task Understanding**: Confirm interpretation of requirements
2. **Approach**: Detailed methodology and reasoning
3. **Execution**: Step-by-step implementation
4. **Validation**: Proof of correctness and completeness
5. **Deliverables**: Final outputs and artifacts
6. **Next Steps**: Recommendations for follow-up actions

## Error Handling
- Identify issues early and communicate immediately
- Provide detailed error analysis and root cause
- Suggest remediation strategies
- Document lessons learned

## Collaboration Protocol
When working with other agents:
- Share relevant context and findings
- Maintain consistent terminology and formats
- Coordinate on shared deliverables
- Validate cross-agent dependencies

Remember: Your role is critical in ensuring tasks that couldn't be handled by the existing 40 agents are executed with the same level of excellence and reliability.`;

  // Write the agent file
  const filename = `${name}.md`;
  const filepath = path.join(AGENTS_DIR, filename);
  
  if (fs.existsSync(filepath)) {
    console.error(`❌ Agent ${name} already exists!`);
    process.exit(1);
  }
  
  fs.writeFileSync(filepath, agentSpec);
  console.log(`✅ Agent specification created: ${filepath}\n`);
  
  // Update the registry
  console.log('📋 Updating agent registry...');
  const { execSync } = await import('child_process');
  try {
    execSync('node ' + path.join(__dirname, 'register-agents.js'), { stdio: 'inherit' });
    console.log('\n✅ Agent registry updated successfully!');
  } catch (error) {
    console.error('⚠️ Failed to update registry. Run scripts/register-agents.js manually.');
  }
  
  // Provide usage instructions
  console.log('\n🎯 HOW TO USE YOUR NEW AGENT:\n');
  console.log('```javascript');
  console.log('Task({');
  console.log('  subagent_type: "general-purpose",');
  console.log(`  prompt: "Act as ${name}. [Include system prompt from AGENT_REGISTRY.md]. Task: [your task]"`);
  console.log('});');
  console.log('```\n');
  
  console.log('📌 NEXT STEPS:');
  console.log('1. Review the agent in .claude/AGENT_REGISTRY.md');
  console.log('2. Test the agent with a sample task');
  console.log('3. Refine the system prompt if needed');
  console.log('4. Commit the new agent to git\n');
  
  rl.close();
}

// Run the wizard
createAgent().catch(console.error);