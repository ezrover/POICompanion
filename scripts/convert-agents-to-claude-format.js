#!/usr/bin/env node

/**
 * Convert Agents to Claude Code Format
 * 
 * Converts our 41 agent specifications to the official Claude Code format
 * with proper YAML frontmatter structure that Claude Code recognizes.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const AGENTS_DIR = path.join(__dirname, '../.claude/agents');

function convertAgent(content, filename) {
  const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
  if (!yamlMatch) {
    console.log(`⚠️  No YAML frontmatter found in ${filename}`);
    return content;
  }
  
  const yamlContent = yamlMatch[1];
  const nameMatch = yamlContent.match(/name:\s*(.+)/);
  const descMatch = yamlContent.match(/description:\s*(.+)/);
  
  if (!nameMatch || !descMatch) {
    console.log(`⚠️  Missing name or description in ${filename}`);
    return content;
  }
  
  const name = nameMatch[1].trim();
  const description = descMatch[1].trim();
  const systemPrompt = content.substring(yamlMatch[0].length).trim();
  
  // Convert to Claude Code format
  const claudeFormat = `---
name: ${name}
description: ${description}
---

${systemPrompt}`;

  return claudeFormat;
}

async function main() {
  console.log('🔄 Converting agents to Claude Code format...\n');
  
  const files = fs.readdirSync(AGENTS_DIR);
  const agentFiles = files.filter(f => f.startsWith('agent-') && f.endsWith('.md'));
  
  let converted = 0;
  
  for (const file of agentFiles) {
    const filePath = path.join(AGENTS_DIR, file);
    const content = fs.readFileSync(filePath, 'utf-8');
    const convertedContent = convertAgent(content, file);
    
    if (convertedContent !== content) {
      fs.writeFileSync(filePath, convertedContent);
      console.log(`✅ Converted: ${file}`);
      converted++;
    } else {
      console.log(`ℹ️  Already correct: ${file}`);
    }
  }
  
  console.log(`\n🎯 Conversion complete! ${converted} agents converted to Claude Code format.`);
  console.log(`\n📋 Next steps:`);
  console.log(`1. Claude Code should now recognize all ${agentFiles.length} agents`);
  console.log(`2. Use Task tool with specific agent names directly`);
  console.log(`3. Test with: Task(subagent_type: "agent-ux-user-experience", ...)`);
}

main().catch(console.error);