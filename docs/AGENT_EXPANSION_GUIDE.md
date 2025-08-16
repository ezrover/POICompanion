# Agent Expansion Guide

## When to Create New Agents

The current 43-agent workforce covers most development scenarios, but new agents should be created when:

1. **Capability Gap**: Existing agents lack specific expertise needed
2. **Validation Gap**: Current agents cannot prove task completion reliably
3. **Domain Gap**: New technology or platform not covered by existing agents
4. **Quality Gap**: Higher precision or specialization required than current agents provide

## Agent Creation Process

### Step 1: Identify the Gap
Before creating a new agent, document:
- What specific task cannot be completed by existing agents
- Why existing agents are inadequate
- What expertise is missing from the workforce
- How the new agent will validate its work

### Step 2: Propose the Agent
Use this template when proposing a new agent:

```markdown
🆕 SUGGESTED NEW AGENT: agent-[domain]-[specialization]

**Gap Identified:** [What current agents cannot do]
**Proposed Expertise:** [Specific capabilities needed]
**Validation Methods:** [How it proves task completion]
**Integration:** [How it works with existing agents]
**Use Cases:** [Specific scenarios where needed]

Shall I create this agent? (yes/no)
```

### Step 3: Create the Agent
Upon approval, use the creation wizard:

```bash
node scripts/create-agent.js
```

The wizard will:
1. Guide you through agent specification
2. Create the agent file in `.claude/agents/`
3. Update the AGENT_REGISTRY.md
4. Provide usage instructions

### Step 4: Test the Agent
Test your new agent immediately:

Use Claude Code Task tool with the new agent name directly:
```javascript
// In Claude Code interface, use Task tool with new agent name
// The agent should appear in the available subagent_type list
```

### Step 5: Document and Commit
1. Verify agent appears in `.claude/AGENT_REGISTRY.md`
2. Test with real-world scenarios
3. Commit the new agent to git
4. Update this guide if new patterns emerge

## Examples of Good Agent Candidates

### ✅ GOOD: agent-blockchain-smart-contract
- **Gap**: No current agent specializes in blockchain/Web3
- **Expertise**: Solidity, smart contracts, DeFi protocols
- **Validation**: Contract verification, gas optimization metrics
- **Integration**: Works with agent-security-sentinel for audits

### ✅ GOOD: agent-video-processing
- **Gap**: No agent for video/media processing
- **Expertise**: FFmpeg, video codecs, streaming protocols
- **Validation**: Output quality metrics, performance benchmarks
- **Integration**: Works with agent-performance-guru for optimization

### ❌ BAD: agent-button-maker
- **Why Bad**: Too narrow - covered by existing UI/UX agents
- **Better**: Enhance agent-ux-user-experience with button expertise

### ❌ BAD: agent-todo-list
- **Why Bad**: Too simple - any agent can handle basic lists
- **Better**: Use agent-tasks for project management

## Agent Naming Convention

Follow this pattern: `agent-[domain]-[specialization]`

- **Domain**: Primary area (e.g., mobile, web, data, security)
- **Specialization**: Specific expertise (e.g., optimizer, architect, analyst)

Examples:
- `agent-mobile-performance`
- `agent-data-pipeline`
- `agent-security-penetration`
- `agent-cloud-cost-optimizer`

## Quality Standards for New Agents

Every new agent must:

1. **Have Clear Purpose**: Solve a specific gap not covered by existing agents
2. **Provide Validation**: Include mechanisms to prove task completion
3. **Document Integration**: Explain how it works with existing agents
4. **Follow Standards**: Match quality level of existing 43 agents
5. **Include Examples**: Provide usage examples in specification

## Maintenance and Evolution

### Regular Review
- Quarterly review of agent usage statistics
- Identify underused agents for improvement or removal
- Identify overused agents that need specialization splitting

### Agent Deprecation
When an agent becomes obsolete:
1. Mark as deprecated in AGENT_REGISTRY.md
2. Suggest replacement agents
3. Provide migration guide
4. Remove after grace period

### Agent Merging
When agents overlap significantly:
1. Identify common functionality
2. Create unified agent with combined expertise
3. Deprecate individual agents
4. Update all references

## Current Agent Categories

Before creating a new agent, check if it fits existing categories:

1. **Workflow Management** (1 agent) - Orchestration and coordination
2. **Development** (8 agents) - Platform-specific implementation
3. **Architecture** (5 agents) - System design and structure
4. **Quality & Testing** (4 agents) - Validation and verification
5. **Business & Strategy** (6 agents) - Analysis and planning
6. **Data & AI** (5 agents) - ML and data processing
7. **Infrastructure** (4 agents) - Operations and deployment
8. **Specialized** (7 agents) - Domain-specific expertise

Total: 43 agents

## Quick Reference

### Check if agent exists:
```bash
grep "agent-your-agent" .claude/AGENT_REGISTRY.md
```

### Create new agent:
```bash
node scripts/create-agent.js
```

### Update registry:
```bash
node scripts/register-agents.js
```

### Test agent:
Use Claude Code Task tool with agent name:
```javascript
// In Claude Code interface: 
// Task tool → subagent_type: "agent-your-agent" → prompt: "[test task]"
```

Remember: The goal is a comprehensive but focused workforce. Only add agents that provide unique, irreplaceable value.