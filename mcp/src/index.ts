#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ErrorCode,
  ListToolsRequestSchema,
  McpError,
} from '@modelcontextprotocol/sdk/types.js';
import { exec } from 'child_process';
import * as path from 'path';
import { promisify } from 'util';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const execAsync = promisify(exec);

/**
 * POI Companion MCP Server
 * 
 * A comprehensive Model Context Protocol server for mobile development,
 * providing 24+ specialized tools for iOS/Android development, testing,
 * performance optimization, and quality assurance.
 */

interface MCPTool {
  name: string;
  description: string;
  inputSchema: {
    type: string;
    properties: Record<string, any>;
    required?: string[];
  };
}

class POICompanionMCPServer {
  private server: Server;
  private projectRoot: string;

  constructor() {
    this.server = new Server(
      {
        name: 'poi-companion-mcp-server',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.projectRoot = path.resolve(__dirname, '..', '..');
    this.setupToolHandlers();
    this.setupErrorHandling();
  }

  private setupErrorHandling(): void {
    this.server.onerror = (error) => {
      console.error('[MCP Error]', error);
    };

    process.on('SIGINT', async () => {
      await this.server.close();
      process.exit(0);
    });
  }

  private setupToolHandlers(): void {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: this.getToolDefinitions(),
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      try {
        return await this.handleToolCall(request.params.name, request.params.arguments || {});
      } catch (error) {
        throw new McpError(
          ErrorCode.InternalError,
          `Tool execution failed: ${error instanceof Error ? error.message : String(error)}`
        );
      }
    });
  }

  private getToolDefinitions(): MCPTool[] {
    return [
      // Mobile Development Tools
      {
        name: 'mobile_build_verify',
        description: 'Verify iOS/Android builds with intelligent error analysis and auto-fixes',
        inputSchema: {
          type: 'object',
          properties: {
            platform: {
              type: 'string',
              enum: ['ios', 'android', 'both'],
              description: 'Target platform to build'
            },
            clean: {
              type: 'boolean',
              description: 'Clean before building',
              default: false
            },
            autoFix: {
              type: 'boolean', 
              description: 'Attempt automatic fixes for common issues',
              default: false
            },
            detailed: {
              type: 'boolean',
              description: 'Show detailed error analysis',
              default: false
            }
          },
          required: ['platform']
        }
      },
      {
        name: 'mobile_test_run',
        description: 'Execute comprehensive mobile app tests with detailed reporting',
        inputSchema: {
          type: 'object',
          properties: {
            platform: {
              type: 'string',
              enum: ['ios', 'android', 'both'],
              description: 'Target platform for testing'
            },
            testType: {
              type: 'string',
              enum: ['unit', 'integration', 'ui', 'all'],
              description: 'Type of tests to run',
              default: 'all'
            },
            coverage: {
              type: 'boolean',
              description: 'Generate coverage report',
              default: false
            }
          },
          required: ['platform']
        }
      },
      {
        name: 'mobile_lint_check',
        description: 'Code quality analysis and style enforcement for mobile projects',
        inputSchema: {
          type: 'object',
          properties: {
            platform: {
              type: 'string',
              enum: ['ios', 'android', 'both'],
              description: 'Target platform for linting'
            },
            autoFix: {
              type: 'boolean',
              description: 'Automatically fix linting issues',
              default: false
            },
            severity: {
              type: 'string',
              enum: ['error', 'warning', 'all'],
              description: 'Minimum severity level to report',
              default: 'warning'
            }
          },
          required: ['platform']
        }
      },
      {
        name: 'android_emulator_test',
        description: 'Automated Android emulator testing with UI validation',
        inputSchema: {
          type: 'object',
          properties: {
            action: {
              type: 'string',
              enum: ['lost-lake-test', 'validate-components', 'monitor-performance', 'test-voice-interface'],
              description: 'Test action to perform'
            },
            duration: {
              type: 'number',
              description: 'Duration for monitoring tests in seconds',
              default: 30
            },
            command: {
              type: 'string',
              description: 'Voice command to test (for voice interface testing)'
            }
          },
          required: ['action']
        }
      },
      {
        name: 'ios_simulator_test',
        description: 'Automated iOS simulator testing with accessibility validation',
        inputSchema: {
          type: 'object',
          properties: {
            action: {
              type: 'string',
              enum: ['lost-lake-test', 'validate-buttons', 'test-accessibility', 'test-carplay'],
              description: 'Test action to perform'
            },
            voiceOver: {
              type: 'boolean',
              description: 'Enable VoiceOver for accessibility testing',
              default: false
            },
            scenario: {
              type: 'string',
              description: 'CarPlay scenario to test'
            }
          },
          required: ['action']
        }
      },
      // Code Quality & Architecture Tools
      {
        name: 'code_generate',
        description: 'Generate boilerplate code and components from templates',
        inputSchema: {
          type: 'object',
          properties: {
            type: {
              type: 'string',
              enum: ['component', 'test', 'feature', 'screen'],
              description: 'Type of code to generate'
            },
            platform: {
              type: 'string',
              enum: ['ios', 'android', 'web', 'cross-platform'],
              description: 'Target platform'
            },
            name: {
              type: 'string',
              description: 'Name of the component/feature to generate'
            },
            template: {
              type: 'string',
              description: 'Specific template to use'
            }
          },
          required: ['type', 'platform', 'name']
        }
      },
      {
        name: 'performance_profile',
        description: 'Analyze app performance and provide optimization recommendations',
        inputSchema: {
          type: 'object',
          properties: {
            action: {
              type: 'string',
              enum: ['baseline', 'monitor', 'analyze', 'report'],
              description: 'Performance profiling action'
            },
            platform: {
              type: 'string',
              enum: ['ios', 'android', 'both'],
              description: 'Target platform'
            },
            duration: {
              type: 'number',
              description: 'Monitoring duration in seconds',
              default: 60
            }
          },
          required: ['action', 'platform']
        }
      },
      {
        name: 'accessibility_check',
        description: 'Validate WCAG compliance and accessibility standards',
        inputSchema: {
          type: 'object',
          properties: {
            action: {
              type: 'string',
              enum: ['scan', 'test', 'report', 'watch'],
              description: 'Accessibility check action'
            },
            standard: {
              type: 'string',
              enum: ['wcag-a', 'wcag-aa', 'wcag-aaa'],
              description: 'WCAG compliance level',
              default: 'wcag-aa'
            },
            platform: {
              type: 'string',
              enum: ['ios', 'android', 'web', 'all'],
              description: 'Platform to check'
            }
          },
          required: ['action']
        }
      },
      {
        name: 'design_system_manage',
        description: 'Manage design system components and consistency',
        inputSchema: {
          type: 'object',
          properties: {
            action: {
              type: 'string',
              enum: ['validate', 'generate', 'sync', 'audit'],
              description: 'Design system action'
            },
            component: {
              type: 'string',
              description: 'Specific component to manage'
            },
            platform: {
              type: 'string',
              enum: ['ios', 'android', 'web', 'all'],
              description: 'Target platform'
            }
          },
          required: ['action']
        }
      },
      // Project Management Tools
      {
        name: 'task_manage',
        description: 'Structured development task management and tracking',
        inputSchema: {
          type: 'object',
          properties: {
            action: {
              type: 'string',
              enum: ['create', 'list', 'update', 'complete', 'status'],
              description: 'Task management action'
            },
            task: {
              type: 'string',
              description: 'Task description or ID'
            },
            priority: {
              type: 'string',
              enum: ['low', 'medium', 'high', 'critical'],
              description: 'Task priority level'
            }
          },
          required: ['action']
        }
      },
      {
        name: 'dependency_manage',
        description: 'Project dependencies and version management',
        inputSchema: {
          type: 'object',
          properties: {
            action: {
              type: 'string',
              enum: ['validate', 'update', 'check', 'audit'],
              description: 'Dependency management action'
            },
            platform: {
              type: 'string',
              enum: ['ios', 'android', 'web', 'all'],
              description: 'Platform to manage dependencies for'
            }
          },
          required: ['action']
        }
      },
      {
        name: 'build_coordinate',
        description: 'Cross-platform build coordination and automation',
        inputSchema: {
          type: 'object',
          properties: {
            action: {
              type: 'string',
              enum: ['build', 'test', 'deploy', 'validate'],
              description: 'Build coordination action'
            },
            platforms: {
              type: 'array',
              items: {
                type: 'string',
                enum: ['ios', 'android', 'web']
              },
              description: 'Platforms to coordinate builds for'
            },
            parallel: {
              type: 'boolean',
              description: 'Execute builds in parallel',
              default: true
            }
          },
          required: ['action', 'platforms']
        }
      },
      // Documentation & Analysis Tools
      {
        name: 'doc_process',
        description: 'Document analysis and processing for implementation context',
        inputSchema: {
          type: 'object',
          properties: {
            action: {
              type: 'string',
              enum: ['analyze', 'generate', 'validate', 'convert'],
              description: 'Document processing action'
            },
            source: {
              type: 'string',
              description: 'Source document or path'
            },
            format: {
              type: 'string',
              enum: ['markdown', 'html', 'json', 'pdf'],
              description: 'Output format'
            }
          },
          required: ['action']
        }
      },
      {
        name: 'spec_generate',
        description: 'Generate technical specifications from requirements',
        inputSchema: {
          type: 'object',
          properties: {
            type: {
              type: 'string',
              enum: ['requirements', 'design', 'api', 'test'],
              description: 'Type of specification to generate'
            },
            feature: {
              type: 'string',
              description: 'Feature name or description'
            },
            template: {
              type: 'string',
              description: 'Template to use for generation'
            }
          },
          required: ['type', 'feature']
        }
      }
    ];
  }

  private async handleToolCall(name: string, args: any): Promise<any> {
    console.log(`[MCP] Executing tool: ${name}`, args);

    switch (name) {
      case 'mobile_build_verify':
        return await this.mobileBuildVerify(args);
      case 'mobile_test_run':
        return await this.mobileTestRun(args);
      case 'mobile_lint_check':
        return await this.mobileLintCheck(args);
      case 'android_emulator_test':
        return await this.androidEmulatorTest(args);
      case 'ios_simulator_test':
        return await this.iosSimulatorTest(args);
      case 'code_generate':
        return await this.codeGenerate(args);
      case 'performance_profile':
        return await this.performanceProfile(args);
      case 'accessibility_check':
        return await this.accessibilityCheck(args);
      case 'design_system_manage':
        return await this.designSystemManage(args);
      case 'task_manage':
        return await this.taskManage(args);
      case 'dependency_manage':
        return await this.dependencyManage(args);
      case 'build_coordinate':
        return await this.buildCoordinate(args);
      case 'doc_process':
        return await this.docProcess(args);
      case 'spec_generate':
        return await this.specGenerate(args);
      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  }

  // Tool Implementation Methods
  private async mobileBuildVerify(args: any) {
    const { platform, clean = false, autoFix = false, detailed = false } = args;
    const toolPath = path.join(__dirname, '../mobile-build-verifier/index.js');
    
    let cmd = `node "${toolPath}" ${platform}`;
    if (clean) cmd += ' --clean';
    if (autoFix) cmd += ' --fix';
    if (detailed) cmd += ' --detailed';

    try {
      const { stdout, stderr } = await execAsync(cmd, { 
        cwd: this.projectRoot,
        timeout: 300000 // 5 minute timeout
      });
      
      return {
        content: [{
          type: 'text',
          text: `Mobile Build Verification Results:\n\n${stdout}${stderr ? `\nErrors: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Build verification failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async mobileTestRun(args: any) {
    const { platform, testType = 'all', coverage = false } = args;
    const toolPath = path.join(__dirname, '../mobile-test-runner/index.js');
    
    let cmd = `node "${toolPath}" ${platform}`;
    if (testType !== 'all') cmd += ` --type ${testType}`;
    if (coverage) cmd += ' --coverage';

    try {
      const { stdout, stderr } = await execAsync(cmd, { 
        cwd: this.projectRoot,
        timeout: 600000 // 10 minute timeout
      });
      
      return {
        content: [{
          type: 'text',
          text: `Mobile Test Results:\n\n${stdout}${stderr ? `\nWarnings: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Test execution failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async mobileLintCheck(args: any) {
    const { platform, autoFix = false, severity = 'warning' } = args;
    const toolPath = path.join(__dirname, '../mobile-linter/index.js');
    
    let cmd = `node "${toolPath}" ${platform}`;
    if (autoFix) cmd += ' --auto-fix';
    cmd += ` --severity ${severity}`;

    try {
      const { stdout, stderr } = await execAsync(cmd, { cwd: this.projectRoot });
      
      return {
        content: [{
          type: 'text',
          text: `Mobile Lint Results:\n\n${stdout}${stderr ? `\nIssues: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Lint check failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async androidEmulatorTest(args: any) {
    const { action, duration = 30, command } = args;
    const toolPath = path.join(__dirname, '../android-emulator-manager/index.js');
    
    let cmd = `node "${toolPath}" ${action}`;
    if (duration && action === 'monitor-performance') cmd += ` --duration=${duration}`;
    if (command && action === 'test-voice-interface') cmd += ` --command="${command}"`;

    try {
      const { stdout, stderr } = await execAsync(cmd, { 
        cwd: this.projectRoot,
        timeout: (duration + 60) * 1000 // Add buffer to duration
      });
      
      return {
        content: [{
          type: 'text',
          text: `Android Emulator Test Results:\n\n${stdout}${stderr ? `\nIssues: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Android emulator test failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async iosSimulatorTest(args: any) {
    const { action, voiceOver = false, scenario } = args;
    const toolPath = path.join(__dirname, '../ios-simulator-manager/index.js');
    
    let cmd = `node "${toolPath}" ${action}`;
    if (voiceOver && action === 'test-accessibility') cmd += ' --voiceover=enabled';
    if (scenario && action === 'test-carplay') cmd += ` --scenario="${scenario}"`;

    try {
      const { stdout, stderr } = await execAsync(cmd, { cwd: this.projectRoot });
      
      return {
        content: [{
          type: 'text',
          text: `iOS Simulator Test Results:\n\n${stdout}${stderr ? `\nIssues: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `iOS simulator test failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async codeGenerate(args: any) {
    const { platform, name, template } = args;
    const toolPath = path.join(__dirname, '../code-generator/index.js');
    
    let cmd = `node "${toolPath}" create --feature=${name} --platform=${platform}`;
    if (template) cmd += ` --template=${template}`;

    try {
      const { stdout, stderr } = await execAsync(cmd, { cwd: this.projectRoot });
      
      return {
        content: [{
          type: 'text',
          text: `Code Generation Results:\n\n${stdout}${stderr ? `\nWarnings: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Code generation failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async performanceProfile(args: any) {
    const { action, platform, duration = 60 } = args;
    const toolPath = path.join(__dirname, '../performance-profiler/index.js');
    
    let cmd = `node "${toolPath}" ${action}`;
    if (platform) cmd += ` --platform=${platform}`;
    if (duration && action === 'monitor') cmd += ` --duration=${duration}`;

    try {
      const { stdout, stderr } = await execAsync(cmd, { 
        cwd: this.projectRoot,
        timeout: (duration + 30) * 1000
      });
      
      return {
        content: [{
          type: 'text',
          text: `Performance Profile Results:\n\n${stdout}${stderr ? `\nIssues: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Performance profiling failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async accessibilityCheck(args: any) {
    const { action, standard = 'wcag-aa', platform } = args;
    const toolPath = path.join(__dirname, '../accessibility-checker/index.js');
    
    let cmd = `node "${toolPath}" ${action} --standard=${standard}`;
    if (platform) cmd += ` --platform=${platform}`;

    try {
      const { stdout, stderr } = await execAsync(cmd, { cwd: this.projectRoot });
      
      return {
        content: [{
          type: 'text',
          text: `Accessibility Check Results:\n\n${stdout}${stderr ? `\nIssues: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Accessibility check failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async designSystemManage(args: any) {
    const { action, component, platform } = args;
    const toolPath = path.join(__dirname, '../design-system-manager/index.js');
    
    let cmd = `node "${toolPath}" ${action}`;
    if (component) cmd += ` --component=${component}`;
    if (platform) cmd += ` --platform=${platform}`;

    try {
      const { stdout, stderr } = await execAsync(cmd, { cwd: this.projectRoot });
      
      return {
        content: [{
          type: 'text',
          text: `Design System Management Results:\n\n${stdout}${stderr ? `\nIssues: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Design system management failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async taskManage(args: any) {
    const { action, task, priority } = args;
    const toolPath = path.join(__dirname, '../task-manager/index.js');
    
    let cmd = `node "${toolPath}" ${action}`;
    if (task) cmd += ` --task="${task}"`;
    if (priority) cmd += ` --priority=${priority}`;

    try {
      const { stdout, stderr } = await execAsync(cmd, { cwd: this.projectRoot });
      
      return {
        content: [{
          type: 'text',
          text: `Task Management Results:\n\n${stdout}${stderr ? `\nIssues: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Task management failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async dependencyManage(args: any) {
    const { action, platform } = args;
    const toolPath = path.join(__dirname, '../dependency-manager/index.js');
    
    let cmd = `node "${toolPath}" ${action}`;
    if (platform) cmd += ` --platform=${platform}`;

    try {
      const { stdout, stderr } = await execAsync(cmd, { cwd: this.projectRoot });
      
      return {
        content: [{
          type: 'text',
          text: `Dependency Management Results:\n\n${stdout}${stderr ? `\nIssues: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Dependency management failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async buildCoordinate(args: any) {
    const { action, platforms, parallel = true } = args;
    const toolPath = path.join(__dirname, '../build-master/index.js');
    
    let cmd = `node "${toolPath}" ${action} --platforms=${platforms.join(',')}`;
    if (parallel) cmd += ' --parallel';

    try {
      const { stdout, stderr } = await execAsync(cmd, { 
        cwd: this.projectRoot,
        timeout: 600000 // 10 minutes for builds
      });
      
      return {
        content: [{
          type: 'text',
          text: `Build Coordination Results:\n\n${stdout}${stderr ? `\nIssues: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Build coordination failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async docProcess(args: any) {
    const { action, source, format } = args;
    const toolPath = path.join(__dirname, '../doc-processor/index.js');
    
    let cmd = `node "${toolPath}" ${action}`;
    if (source) cmd += ` --source="${source}"`;
    if (format) cmd += ` --format=${format}`;

    try {
      const { stdout, stderr } = await execAsync(cmd, { cwd: this.projectRoot });
      
      return {
        content: [{
          type: 'text',
          text: `Document Processing Results:\n\n${stdout}${stderr ? `\nIssues: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Document processing failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  private async specGenerate(args: any) {
    const { type, feature, template } = args;
    const toolPath = path.join(__dirname, '../spec-generator/index.js');
    
    let cmd = `node "${toolPath}" ${type} --feature="${feature}"`;
    if (template) cmd += ` --template=${template}`;

    try {
      const { stdout, stderr } = await execAsync(cmd, { cwd: this.projectRoot });
      
      return {
        content: [{
          type: 'text',
          text: `Specification Generation Results:\n\n${stdout}${stderr ? `\nIssues: ${stderr}` : ''}`
        }]
      };
    } catch (error: any) {
      return {
        content: [{
          type: 'text',
          text: `Specification generation failed: ${error.message}\n${error.stdout || ''}\n${error.stderr || ''}`
        }]
      };
    }
  }

  async run(): Promise<void> {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    
    console.error('POI Companion MCP Server running on stdio');
  }
}

const server = new POICompanionMCPServer();
server.run().catch(console.error);