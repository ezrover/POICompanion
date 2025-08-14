#!/usr/bin/env node

/**
 * Update All Agents with MCP Tool Integration
 * 
 * This script adds comprehensive MCP tool sections to all agent specifications
 * that don't already have them, ensuring consistent tool usage across the workforce.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const AGENTS_DIR = path.join(__dirname, '../.claude/agents');

// MCP tool mappings for different agent types
const MCP_SECTIONS = {
  'spec-workflow-manager': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for Workflow Management:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| Task Management | \`task-manager\` | \`node /mcp/task-manager/index.js\` |
| Spec Generation | \`spec-generator\` | \`node /mcp/spec-generator/index.js\` |
| Documentation | \`doc-processor\` | \`node /mcp/doc-processor/index.js\` |
| Project Setup | \`project-scaffolder\` | \`node /mcp/project-scaffolder/index.js\` |
| Agent Registry | \`agent-registry-manager\` | \`node /mcp/agent-registry-manager/index.js\` |

### **Workflow Automation:**
\`\`\`bash
# Initialize spec-driven workflow
node /mcp/spec-generator/index.js init --feature={name}
node /mcp/task-manager/index.js create --spec={spec-file}
node /mcp/doc-processor/index.js generate --type=requirements
\`\`\``,

  'spec-ux-user-experience': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for UX/UI Design:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| UI Generation | \`ui-generator\` | \`node /mcp/ui-generator/index.js\` |
| Design System | \`design-system-manager\` | \`node /mcp/design-system-manager/index.js\` |
| Accessibility | \`accessibility-checker\` | \`node /mcp/accessibility-checker/index.js\` |
| Icon Creation | \`mobile-icon-generator\` | \`node /mcp/mobile-icon-generator/index.js\` |
| Icon Validation | \`mobile-icon-verifier\` | \`node /mcp/mobile-icon-verifier/index.js\` |

### **Design Workflow:**
\`\`\`bash
# Generate UI components
node /mcp/ui-generator/index.js create --component={name}
node /mcp/design-system-manager/index.js validate
node /mcp/accessibility-checker/index.js audit --wcag-aa
\`\`\``,

  'spec-performance-guru': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for Performance Optimization:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| Performance Profiling | \`performance-profiler\` | \`node /mcp/performance-profiler/index.js\` |
| Model Optimization | \`model-optimizer\` | \`node /mcp/model-optimizer/index.js\` |
| Build Optimization | \`build-master\` | \`node /mcp/build-master/index.js\` |
| Mobile Testing | \`mobile-test-runner\` | \`node /mcp/mobile-test-runner/index.js\` |

### **Performance Workflow:**
\`\`\`bash
# Profile and optimize
node /mcp/performance-profiler/index.js analyze --platform={ios|android}
node /mcp/model-optimizer/index.js optimize --target=mobile
node /mcp/build-master/index.js optimize --release
\`\`\``,

  'spec-system-architect': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for System Architecture:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| Project Scaffolding | \`project-scaffolder\` | \`node /mcp/project-scaffolder/index.js\` |
| Build Coordination | \`build-master\` | \`node /mcp/build-master/index.js\` |
| Dependency Management | \`dependency-manager\` | \`node /mcp/dependency-manager/index.js\` |
| Schema Validation | \`schema-validator\` | \`node /mcp/schema-validator/index.js\` |
| Code Generation | \`code-generator\` | \`node /mcp/code-generator/index.js\` |

### **Architecture Workflow:**
\`\`\`bash
# Setup architecture
node /mcp/project-scaffolder/index.js create --architecture={type}
node /mcp/dependency-manager/index.js install --scope=all
node /mcp/schema-validator/index.js validate --strict
\`\`\``,

  'spec-test': `

## 🚨 MCP TOOL INTEGRATION (ALREADY COMPREHENSIVE)

This agent already has excellent MCP tool integration. No updates needed.`,

  'spec-impl': `

## 🚨 MCP TOOL INTEGRATION (ALREADY COMPREHENSIVE)

This agent already has excellent MCP tool integration. No updates needed.`,

  'spec-judge': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for Quality Validation:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| Build Validation | \`mobile-build-verifier\` | \`node /mcp/mobile-build-verifier/index.js both\` |
| Test Validation | \`mobile-test-runner\` | \`node /mcp/mobile-test-runner/index.js\` |
| Code Quality | \`mobile-linter\` | \`node /mcp/mobile-linter/index.js\` |
| Accessibility | \`accessibility-checker\` | \`node /mcp/accessibility-checker/index.js\` |
| Performance | \`performance-profiler\` | \`node /mcp/performance-profiler/index.js\` |

### **Validation Workflow:**
\`\`\`bash
# Comprehensive validation
node /mcp/mobile-build-verifier/index.js both --detailed
node /mcp/mobile-test-runner/index.js all --coverage
node /mcp/accessibility-checker/index.js validate --strict
\`\`\``,

  'spec-accessibility-champion': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for Accessibility:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| Accessibility Audit | \`accessibility-checker\` | \`node /mcp/accessibility-checker/index.js\` |
| UI Validation | \`ui-generator\` | \`node /mcp/ui-generator/index.js --accessible\` |
| Design Compliance | \`design-system-manager\` | \`node /mcp/design-system-manager/index.js\` |
| Mobile Testing | \`mobile-test-runner\` | \`node /mcp/mobile-test-runner/index.js --a11y\` |

### **Accessibility Workflow:**
\`\`\`bash
# Full accessibility audit
node /mcp/accessibility-checker/index.js audit --wcag-aaa
node /mcp/mobile-test-runner/index.js a11y --voiceover
node /mcp/design-system-manager/index.js validate-a11y
\`\`\``,

  'spec-data-scientist': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for Data Science:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| Model Optimization | \`model-optimizer\` | \`node /mcp/model-optimizer/index.js\` |
| Performance Analysis | \`performance-profiler\` | \`node /mcp/performance-profiler/index.js\` |
| Schema Validation | \`schema-validator\` | \`node /mcp/schema-validator/index.js\` |
| Documentation | \`doc-processor\` | \`node /mcp/doc-processor/index.js\` |

### **Data Science Workflow:**
\`\`\`bash
# Model development
node /mcp/model-optimizer/index.js train --data={dataset}
node /mcp/performance-profiler/index.js benchmark --model={name}
node /mcp/schema-validator/index.js validate --data-schema
\`\`\``,

  'spec-cloud-architect': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for Cloud Architecture:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| Build Orchestration | \`build-master\` | \`node /mcp/build-master/index.js\` |
| Dependency Management | \`dependency-manager\` | \`node /mcp/dependency-manager/index.js\` |
| Performance Monitoring | \`performance-profiler\` | \`node /mcp/performance-profiler/index.js\` |
| Schema Validation | \`schema-validator\` | \`node /mcp/schema-validator/index.js\` |

### **Cloud Deployment Workflow:**
\`\`\`bash
# Deploy to cloud
node /mcp/build-master/index.js deploy --env=production
node /mcp/performance-profiler/index.js monitor --cloud
node /mcp/dependency-manager/index.js update --security
\`\`\``,

  'spec-database-architect-developer': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for Database Development:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| Schema Validation | \`schema-validator\` | \`node /mcp/schema-validator/index.js\` |
| Code Generation | \`code-generator\` | \`node /mcp/code-generator/index.js --db\` |
| Performance Testing | \`performance-profiler\` | \`node /mcp/performance-profiler/index.js\` |
| Documentation | \`doc-processor\` | \`node /mcp/doc-processor/index.js\` |

### **Database Workflow:**
\`\`\`bash
# Database operations
node /mcp/schema-validator/index.js validate --database
node /mcp/code-generator/index.js migration --auto
node /mcp/performance-profiler/index.js query --optimize
\`\`\``,

  'spec-web-frontend-developer': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for Web Development:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| UI Generation | \`ui-generator\` | \`node /mcp/ui-generator/index.js react\` |
| Code Generation | \`code-generator\` | \`node /mcp/code-generator/index.js tsx\` |
| Build Management | \`build-master\` | \`node /mcp/build-master/index.js web\` |
| Accessibility | \`accessibility-checker\` | \`node /mcp/accessibility-checker/index.js web\` |
| Performance | \`performance-profiler\` | \`node /mcp/performance-profiler/index.js web\` |

### **Web Development Workflow:**
\`\`\`bash
# Web app development
node /mcp/ui-generator/index.js react --component={name}
node /mcp/code-generator/index.js tsx --hooks
node /mcp/build-master/index.js optimize --web
node /mcp/accessibility-checker/index.js audit --web
\`\`\``,

  'spec-flutter-developer': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for Flutter Development:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| Build Verification | \`mobile-build-verifier\` | \`node /mcp/mobile-build-verifier/index.js flutter\` |
| UI Generation | \`ui-generator\` | \`node /mcp/ui-generator/index.js flutter\` |
| Code Generation | \`code-generator\` | \`node /mcp/code-generator/index.js dart\` |
| Testing | \`mobile-test-runner\` | \`node /mcp/mobile-test-runner/index.js flutter\` |
| Linting | \`mobile-linter\` | \`node /mcp/mobile-linter/index.js flutter\` |

### **Flutter Workflow:**
\`\`\`bash
# Flutter development
node /mcp/ui-generator/index.js flutter --widget={name}
node /mcp/code-generator/index.js dart --bloc
node /mcp/mobile-build-verifier/index.js flutter --all
node /mcp/mobile-test-runner/index.js flutter --coverage
\`\`\``,

  'default': `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| Task Management | \`task-manager\` | \`node /mcp/task-manager/index.js\` |
| Documentation | \`doc-processor\` | \`node /mcp/doc-processor/index.js\` |
| Code Generation | \`code-generator\` | \`node /mcp/code-generator/index.js\` |
| Schema Validation | \`schema-validator\` | \`node /mcp/schema-validator/index.js\` |

### **General Workflow:**
\`\`\`bash
# Use MCP tools instead of direct commands
node /mcp/task-manager/index.js create --task={description}
node /mcp/doc-processor/index.js generate
node /mcp/code-generator/index.js create --template={type}
\`\`\`

**Remember: Direct command usage = Task failure. MCP tools are MANDATORY.**`
};

async function updateAgent(filepath, agentName) {
  const content = fs.readFileSync(filepath, 'utf-8');
  
  // Check if agent already has MCP integration
  if (content.includes('MCP TOOL INTEGRATION')) {
    console.log(`✓ ${agentName} already has MCP integration`);
    return false;
  }
  
  // Get appropriate MCP section
  let mcpSection = MCP_SECTIONS[agentName] || MCP_SECTIONS['default'];
  
  // Special handling for certain agents
  if (agentName.includes('spec-ai-') || agentName.includes('model')) {
    mcpSection = MCP_SECTIONS['spec-data-scientist'] || MCP_SECTIONS['default'];
  } else if (agentName.includes('spec-chrome-extension')) {
    mcpSection = MCP_SECTIONS['spec-web-frontend-developer'] || MCP_SECTIONS['default'];
  } else if (agentName.includes('spec-firmware')) {
    mcpSection = MCP_SECTIONS['default'];
  } else if (agentName.includes('spec-legal') || agentName.includes('spec-regulatory')) {
    mcpSection = MCP_SECTIONS['default'];
  } else if (agentName.includes('spec-market') || agentName.includes('spec-analyst')) {
    mcpSection = `

## 🚨 MCP TOOL INTEGRATION (MANDATORY)

### **Required MCP Tools for Analysis:**

| Operation | MCP Tool | Usage |
|-----------|----------|-------|
| Market Analysis | \`market-analyzer\` | \`node /mcp/market-analyzer/index.js\` |
| Documentation | \`doc-processor\` | \`node /mcp/doc-processor/index.js\` |
| Task Management | \`task-manager\` | \`node /mcp/task-manager/index.js\` |
| Spec Generation | \`spec-generator\` | \`node /mcp/spec-generator/index.js\` |

### **Analysis Workflow:**
\`\`\`bash
# Market and competitive analysis
node /mcp/market-analyzer/index.js research --competitor={name}
node /mcp/doc-processor/index.js analyze --market-data
node /mcp/spec-generator/index.js requirements --from-analysis
\`\`\``;
  }
  
  // Append MCP section
  const updatedContent = content + mcpSection;
  fs.writeFileSync(filepath, updatedContent);
  console.log(`✅ Updated ${agentName} with MCP integration`);
  return true;
}

async function main() {
  console.log('🔍 Updating all agents with MCP tool integration...\n');
  
  const files = fs.readdirSync(AGENTS_DIR);
  const agentFiles = files.filter(f => f.startsWith('spec-') && f.endsWith('.md'));
  
  let updatedCount = 0;
  let skippedCount = 0;
  
  for (const file of agentFiles) {
    const agentName = file.replace('.md', '');
    const filepath = path.join(AGENTS_DIR, file);
    
    const updated = await updateAgent(filepath, agentName);
    if (updated) {
      updatedCount++;
    } else {
      skippedCount++;
    }
  }
  
  console.log(`\n📊 Summary:`);
  console.log(`   Updated: ${updatedCount} agents`);
  console.log(`   Skipped: ${skippedCount} agents (already have MCP integration)`);
  console.log(`   Total: ${agentFiles.length} agents\n`);
  
  if (updatedCount > 0) {
    console.log('✅ All agents now have MCP tool integration!');
    console.log('📝 Remember to commit these changes to git.');
  }
}

main().catch(console.error);