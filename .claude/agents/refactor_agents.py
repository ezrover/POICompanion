#!/usr/bin/env python3
"""
Refactor all spec-*.md files to agent-*.md and update their structure
to follow the agent-python-developer.md template
"""

import os
import re
import glob

def rename_files():
    """Rename all spec-*.md files to agent-*.md"""
    renamed = []
    for old_file in glob.glob("spec-*.md"):
        new_file = old_file.replace("spec-", "agent-")
        os.rename(old_file, new_file)
        renamed.append((old_file, new_file))
        print(f"Renamed: {old_file} -> {new_file}")
    return renamed

def update_file_content(filepath):
    """Update the content of each agent file to follow the standard structure"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Extract YAML front matter
    yaml_match = re.match(r'^---\n(.*?)\n---\n(.*)', content, re.DOTALL)
    if not yaml_match:
        print(f"Warning: No YAML front matter found in {filepath}")
        return False
    
    yaml_content = yaml_match.group(1)
    body_content = yaml_match.group(2)
    
    # Update the name in YAML
    new_name = os.path.basename(filepath).replace('.md', '')
    yaml_content = re.sub(r'name:\s*spec-', 'name: agent-', yaml_content)
    
    # Extract description for better formatting
    desc_match = re.search(r'description:\s*(.+)', yaml_content)
    description = desc_match.group(1) if desc_match else ""
    
    # Create the standard structure
    agent_title = new_name.replace('agent-', '').replace('-', ' ').title()
    
    # Check if this agent uses MCP tools
    uses_mcp = any(keyword in body_content.lower() for keyword in 
                   ['mcp', 'mobile_build_verify', 'test_run', 'accessibility_check', 
                    'performance_profile', 'code_generate', '/mcp/', 'node /'])
    
    # Build new content structure
    new_content = f"""---
name: {new_name}
description: {description}
---

# {agent_title} Agent

## Overview
{description}

## Required MCP Tools
"""
    
    # Add MCP tools section based on content analysis
    if 'mobile_build_verify' in body_content or 'mobile-build-verifier' in body_content:
        new_content += """
### mobile_build_verify
- **Purpose**: Verify mobile app builds for iOS and Android
- **Usage**: Use `mcp__poi-companion__mobile_build_verify` for build verification
"""

    if 'test_run' in body_content or 'test-runner' in body_content or 'e2e_ui_test' in body_content:
        new_content += """
### test_run / e2e_ui_test_run
- **Purpose**: Execute tests and E2E UI tests
- **Usage**: Use `mcp__poi-companion__test_run` or `mcp__poi-companion__e2e_ui_test_run`
"""

    if 'accessibility_check' in body_content or 'accessibility-checker' in body_content:
        new_content += """
### accessibility_check
- **Purpose**: Validate WCAG compliance and accessibility
- **Usage**: Use `mcp__poi-companion__accessibility_check`
"""

    if 'performance_profile' in body_content or 'performance-profiler' in body_content:
        new_content += """
### performance_profile
- **Purpose**: Analyze performance and optimization
- **Usage**: Use `mcp__poi-companion__performance_profile`
"""

    if 'code_generate' in body_content or 'code-generator' in body_content:
        new_content += """
### code_generate
- **Purpose**: Generate boilerplate code and components
- **Usage**: Use `mcp__poi-companion__code_generate`
"""
    
    if not uses_mcp:
        new_content += """
*This agent primarily uses Claude's built-in capabilities and the Task tool for coordination with other agents.*
"""
    
    # Add agent instructions section
    new_content += """
## Agent Instructions
"""
    
    # Clean up the body content - remove old MCP references
    cleaned_body = body_content
    
    # Replace direct MCP tool references with proper MCP server references
    replacements = [
        (r'node /mcp/mobile-build-verifier/index\.js', 'Use `mcp__poi-companion__mobile_build_verify` tool'),
        (r'node /Users/[^/]+/Projects/AI/POICompanion/mcp/mobile-build-verifier/index\.js', 'Use `mcp__poi-companion__mobile_build_verify` tool'),
        (r'node mobile-test-runner/index\.js', 'Use `mcp__poi-companion__mobile_test_run` tool'),
        (r'node test-runner/index\.js', 'Use `mcp__poi-companion__test_run` tool'),
        (r'node e2e-ui-test-runner/index\.js', 'Use `mcp__poi-companion__e2e_ui_test_run` tool'),
        (r'node accessibility-checker/index\.js', 'Use `mcp__poi-companion__accessibility_check` tool'),
        (r'node performance-profiler/index\.js', 'Use `mcp__poi-companion__performance_profile` tool'),
        (r'node code-generator/index\.js', 'Use `mcp__poi-companion__code_generate` tool'),
        (r'node mcp__poi-companion__(\w+)', r'Use `mcp__poi-companion__\1` tool'),
        (r'/mcp/[^/]+/index\.js', 'the appropriate MCP tool'),
    ]
    
    for pattern, replacement in replacements:
        cleaned_body = re.sub(pattern, replacement, cleaned_body)
    
    # Add the cleaned body content
    new_content += cleaned_body
    
    # Write the updated content
    with open(filepath, 'w') as f:
        f.write(new_content)
    
    return True

def update_agent_registry():
    """Update AGENT_REGISTRY.md with new agent names"""
    registry_path = "../AGENT_REGISTRY.md"
    
    if not os.path.exists(registry_path):
        print(f"Warning: {registry_path} not found")
        return
    
    with open(registry_path, 'r') as f:
        content = f.read()
    
    # Replace all spec- references with agent-
    content = re.sub(r'spec-([a-z-]+)\.md', r'agent-\1.md', content)
    content = re.sub(r'### spec-([a-z-]+)', r'### agent-\1', content)
    content = re.sub(r'name: spec-([a-z-]+)', r'name: agent-\1', content)
    content = re.sub(r'"spec-([a-z-]+)"', r'"agent-\1"', content)
    content = re.sub(r'`spec-([a-z-]+)`', r'`agent-\1`', content)
    
    with open(registry_path, 'w') as f:
        f.write(content)
    
    print("Updated AGENT_REGISTRY.md")

def main():
    # Change to agents directory
    os.chdir("/Users/naderrahimizad/Projects/AI/POICompanion/.claude/agents")
    
    print("Step 1: Renaming files...")
    renamed_files = rename_files()
    
    print("\nStep 2: Refactoring agent content...")
    for _, new_file in renamed_files:
        if update_file_content(new_file):
            print(f"Updated: {new_file}")
        else:
            print(f"Failed to update: {new_file}")
    
    print("\nStep 3: Updating AGENT_REGISTRY.md...")
    update_agent_registry()
    
    print("\nRefactoring complete!")
    print(f"Total files renamed and refactored: {len(renamed_files)}")

if __name__ == "__main__":
    main()