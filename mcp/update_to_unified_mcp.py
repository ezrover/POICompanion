#!/usr/bin/env python3
"""
Update all references to use the unified MCP server commands
"""

import os
import re
import glob

# Complete mapping of old references to new MCP commands
REPLACEMENTS = [
    # Model optimizer
    (r'node /mcp/model-optimizer/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__model_optimize tool'),
    
    # Schema validator
    (r'node /mcp/schema-validator/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__schema_validate tool'),
    
    # UI generator
    (r'node /mcp/ui-generator/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__ui_generate tool'),
    
    # Market analyzer
    (r'node /mcp/market-analyzer/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__market_analyze tool'),
    
    # Icon generator and verifier
    (r'node /mcp/mobile-icon-generator/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__icon_generate tool'),
    (r'node /mcp/mobile-icon-verifier/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__icon_verify tool'),
    
    # File manager
    (r'node /mcp/mobile-file-manager/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__file_manage tool'),
    
    # Project managers
    (r'node /mcp/android-project-manager/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__android_project_manage tool'),
    (r'node /mcp/ios-project-manager/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__ios_project_manage tool'),
    
    # Agent registry manager
    (r'node /mcp/agent-registry-manager/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__agent_registry_manage tool'),
    
    # Project scaffolder
    (r'node /mcp/project-scaffolder/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__project_scaffold tool'),
    
    # Test runner
    (r'node /mcp/test-runner/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__test_run tool'),
    
    # QA validator
    (r'node /mcp/mobile-qa-validator/index\.js \[NOT IN UNIFIED MCP YET\]', 
     'Use mcp__poi-companion__qa_validate tool'),
    
    # Also update any remaining old patterns
    (r'node test-runner/index\.js', 'Use mcp__poi-companion__test_run tool'),
    (r'node project-scaffolder/index\.js', 'Use mcp__poi-companion__project_scaffold tool'),
    (r'node mobile-file-manager/index\.js', 'Use mcp__poi-companion__file_manage tool'),
    (r'node ui-generator/index\.js', 'Use mcp__poi-companion__ui_generate tool'),
    (r'node schema-validator/index\.js', 'Use mcp__poi-companion__schema_validate tool'),
]

# Specific command patterns that need updating
COMMAND_PATTERNS = [
    # Model optimizer specific commands
    (r'node /mcp/model-optimizer/index\.js \[NOT IN UNIFIED MCP YET\] train --data=\{dataset\}',
     'Use mcp__poi-companion__model_optimize tool with action: "train", dataset: "{dataset}"'),
    
    # Schema validator patterns
    (r'node /mcp/schema-validator/index\.js \[NOT IN UNIFIED MCP YET\] validate',
     'Use mcp__poi-companion__schema_validate tool with action: "validate"'),
    
    # UI generator patterns
    (r'node /mcp/ui-generator/index\.js \[NOT IN UNIFIED MCP YET\] react --component=\{name\}',
     'Use mcp__poi-companion__ui_generate tool with framework: "react", component: "{name}"'),
    (r'node /mcp/ui-generator/index\.js \[NOT IN UNIFIED MCP YET\] compose --screen=destination',
     'Use mcp__poi-companion__ui_generate tool with framework: "compose", screen: "destination"'),
    (r'node /mcp/ui-generator/index\.js \[NOT IN UNIFIED MCP YET\] compose',
     'Use mcp__poi-companion__ui_generate tool with framework: "compose"'),
    
    # Market analyzer patterns
    (r'node /mcp/market-analyzer/index\.js \[NOT IN UNIFIED MCP YET\] research --competitor=\{name\}',
     'Use mcp__poi-companion__market_analyze tool with action: "research", competitor: "{name}"'),
    
    # Icon generator patterns
    (r'node /mcp/mobile-icon-generator/index\.js \[NOT IN UNIFIED MCP YET\] android --source=logo\.svg',
     'Use mcp__poi-companion__icon_generate tool with platform: "android", source: "logo.svg"'),
    (r'node /mcp/mobile-icon-generator/index\.js \[NOT IN UNIFIED MCP YET\] android',
     'Use mcp__poi-companion__icon_generate tool with platform: "android"'),
    
    # Icon verifier patterns
    (r'node /mcp/mobile-icon-verifier/index\.js \[NOT IN UNIFIED MCP YET\] android --validate-all',
     'Use mcp__poi-companion__icon_verify tool with platform: "android", validateAll: true'),
    (r'node /mcp/mobile-icon-verifier/index\.js \[NOT IN UNIFIED MCP YET\] android',
     'Use mcp__poi-companion__icon_verify tool with platform: "android"'),
    
    # Project scaffolder patterns
    (r'node /mcp/project-scaffolder/index\.js \[NOT IN UNIFIED MCP YET\] android --template=compose',
     'Use mcp__poi-companion__project_scaffold tool with platform: "android", template: "compose"'),
    
    # Android project manager patterns
    (r'node /mcp/android-project-manager/index\.js \[NOT IN UNIFIED MCP YET\] init',
     'Use mcp__poi-companion__android_project_manage tool with action: "init"'),
    (r'node /mcp/android-project-manager/index\.js \[NOT IN UNIFIED MCP YET\] add-deps',
     'Use mcp__poi-companion__android_project_manage tool with action: "add-deps"'),
    (r'node /mcp/android-project-manager/index\.js \[NOT IN UNIFIED MCP YET\] add-auto-support',
     'Use mcp__poi-companion__android_project_manage tool with action: "add-auto-support"'),
    
    # File manager patterns
    (r'node /mcp/mobile-file-manager/index\.js \[NOT IN UNIFIED MCP YET\] android',
     'Use mcp__poi-companion__file_manage tool with action: "scan", platform: "android"'),
]

def update_file(filepath):
    """Update a single file with new MCP references"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_content = content
    changes_made = 0
    
    # Apply command pattern replacements first (more specific)
    for pattern, replacement in COMMAND_PATTERNS:
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            changes_made += 1
    
    # Apply general replacements
    for pattern, replacement in REPLACEMENTS:
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            changes_made += 1
    
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        return changes_made
    return 0

def main():
    files_to_update = []
    
    # Update all spec-*.md files
    agent_files = glob.glob('/Users/naderrahimizad/Projects/AI/POICompanion/.claude/agents/spec-*.md')
    files_to_update.extend(agent_files)
    
    # Update AGENT_REGISTRY.md
    files_to_update.append('/Users/naderrahimizad/Projects/AI/POICompanion/.claude/AGENT_REGISTRY.md')
    
    # Update CLAUDE.md
    claude_md = '/Users/naderrahimizad/Projects/AI/POICompanion/CLAUDE.md'
    if os.path.exists(claude_md):
        files_to_update.append(claude_md)
    
    # Update README files
    readme_files = glob.glob('/Users/naderrahimizad/Projects/AI/POICompanion/**/*.md', recursive=True)
    files_to_update.extend([f for f in readme_files if 'node_modules' not in f])
    
    total_changes = 0
    updated_files = 0
    
    for filepath in files_to_update:
        if os.path.exists(filepath):
            changes = update_file(filepath)
            if changes > 0:
                print(f"Updated: {os.path.basename(filepath)} ({changes} changes)")
                updated_files += 1
                total_changes += changes
    
    print(f"\n✅ Updated {updated_files} files with {total_changes} total changes")
    print("\nAll tools are now integrated into the unified MCP server!")
    print("Use 'mcp__poi-companion__' prefix for all MCP tool commands")

if __name__ == '__main__':
    main()