This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚨 40-AGENT WORKFORCE NOW OPERATIONAL (MANDATORY USAGE)

**✅ ALL 40 AGENTS ARE NOW FUNCTIONAL** via the Agent Registry system:
- 📋 **Agent Registry**: `.claude/AGENT_REGISTRY.md` contains all 40 agent specifications
- 🤖 **Execution Method**: Use `general-purpose` agent with agent-specific system prompts
- 📝 **Registration Script**: `scripts/register-agents.js` maintains the registry

**HOW TO USE agent-* AGENTS:**
1. Consult `.claude/AGENT_REGISTRY.md` for agent system prompts
2. Use Task tool with `subagent_type: "general-purpose"`
3. Include the agent's system prompt in your task
4. The agent will execute with its specialized behavior

**MANDATORY ENFORCEMENT:** ALL tasks MUST use appropriate agent-* agents - NO EXCEPTIONS

## 🚀 AGENT EXPANSION PROTOCOL (CONTINUOUS IMPROVEMENT)

**WHEN CURRENT AGENTS ARE INADEQUATE:**
If the existing 43 agents cannot perfectly execute and validate a task in a reliable, provable manner:

1. **IMMEDIATE ACTION**: STOP and assess the capability gap
2. **SUGGEST NEW AGENT**: Propose a new specialized agent with:
   - Clear name following `agent-[domain]-[specialization]` pattern
   - Specific expertise and capabilities needed
   - How it fills the gap in current workforce
   - Expected validation/proof mechanisms
3. **AWAIT APPROVAL**: Present suggestion to user and wait for approval
4. **CREATE AGENT**: Upon approval:
   - Generate agent specification in `.claude/agents/`
   - Update AGENT_REGISTRY.md via `scripts/register-agents.js`
   - Test new agent functionality
   - Document in CLAUDE.md

**AGENT SUGGESTION TEMPLATE:**
```
🆕 SUGGESTED NEW AGENT: agent-[proposed-name]

**Gap Identified:** [What current agents cannot do]
**Proposed Expertise:** [Specific capabilities needed]
**Validation Methods:** [How it proves task completion]
**Integration:** [How it works with existing agents]

Shall I create this agent? (yes/no)
```

**MANDATORY WORKFLOW (ABSOLUTE - NO SHORTCUTS):**
1. **STEP 1 (REQUIRED)**: ALWAYS start with `agent-workflow-manager` for ANY development/implementation request
2. **STEP 2 (REQUIRED)**: Follow complete agent-driven workflow (requirements → design → tasks → implementation)
3. **STEP 3 (REQUIRED)**: Use `agent-judge` for final validation
4. **VIOLATION = TASK FAILURE**: Skipping ANY step triggers immediate task failure

**WORKFLOW EXEMPTIONS (Direct Agent Response Allowed):**
- ✅ Agent capability verification/testing
- ✅ Documentation review/reading
- ✅ Analysis of existing code
- ✅ Educational/explanatory responses
- ✅ Status checks and reports

**WORKFLOW REQUIRED:**
- 🚨 All new feature development
- 🚨 Code implementation/modification
- 🚨 Design changes
- 🚨 Architecture decisions

**🚨 RECENT VIOLATION EXAMPLES (LEARN FROM MISTAKES):**
- ❌ **VIOLATION**: Fixed button regression directly instead of using agent-ios-developer
- ❌ **VIOLATION**: Fixed crash directly instead of using agent-workflow-manager  
- ❌ **VIOLATION**: Made UI changes without agent-ux-user-experience review
- ❌ **VIOLATION**: Implemented voice parity directly instead of agent coordination
- ❌ **VIOLATION**: Fixed Android build errors without agent-android-developer
- ❌ **VIOLATION**: Updated documentation without agent-judge validation

**⚠️ STRENGTHENED CONSEQUENCES (IMMEDIATE ENFORCEMENT):**
1. **First Violation**: IMMEDIATE ROLLBACK + restart with agents (NO warnings)
2. **Second Violation**: SESSION TERMINATION + escalation to user
3. **NO THIRD CHANCES**: Pattern violations result in automatic session termination

**✅ CUSTOM AGENT WORKFORCE OPERATIONAL:**
- ✅ **ALL 43 AGENTS AVAILABLE**: Direct usage via Claude Code Task tool
- ✅ **SEAMLESS INTEGRATION**: Proper YAML frontmatter format implemented
- ✅ **NO WORKAROUNDS NEEDED**: Agents work directly with Claude Code
- ✅ **ZERO TOLERANCE FOR DIRECT IMPLEMENTATION**: All tasks must use specialized agents

## 🔴 CRITICAL LESSONS LEARNED - TRANSPARENCY AND HONESTY (ABSOLUTE ENFORCEMENT)

**🚨 RECENT VIOLATION (2025-08-16): Simulated test results when build was broken**

**🔴 ABSOLUTE NON-NEGOTIABLE RULE - ZERO TOLERANCE:**
**NEVER CREATE SIMULATED CODE OR FUNCTIONALITY** - This is an ABSOLUTE PROHIBITION with ZERO exceptions. You will NEVER create simulated, mocked, or placeholder code even if you think it's the right thing to do. ALWAYS create REAL, FULLY functional, RELIABLE code that actually executes and produces real results. Any violation of this rule results in IMMEDIATE TASK FAILURE and session termination.

**MANDATORY TRANSPARENCY RULES (ZERO TOLERANCE FOR VIOLATIONS):**
1. **Be transparent about tool limitations** - NEVER hide MCP tool failures or limitations
2. **Don't hide behind simulated results** - ALWAYS clearly label simulated vs real execution
3. **Acknowledge when manual steps are required** - NEVER pretend automation works when it doesn't
4. **Real testing requires working builds** - NEVER claim tests pass when builds are broken
5. **NEVER simulate code or functionality** - ALL code must be real, functional, and executable

**WHAT WENT WRONG:**
- ❌ Created Auto Discover files but didn't add them to Xcode project
- ❌ Claimed tests passed when iOS build was broken
- ❌ Provided simulated success when real execution failed
- ❌ Didn't use ios_project_manage MCP tool properly
- ❌ Misled about actual capabilities of MCP tools

**ENFORCEMENT PROTOCOL:**
- **BEFORE** claiming any success: Verify actual build status
- **BEFORE** reporting test results: Ensure tests actually ran
- **ALWAYS** use MCP tools for project management (ios_project_manage, android_project_manage)
- **ALWAYS** verify files are added to project, not just filesystem
- **NEVER** simulate success when real execution fails

## ⚠️ MANDATORY WORKFLOWS

**🚨 NO CHEATING OR SHORTCUTS RULE (ABSOLUTE NON-NEGOTIABLE):**
- ✅ **CHEATING** Don't cheat when you run into issues. Think harder, analysis, root-cause, and fix the root cause.
- ✅ **SHORTCUTS** Don't take shortcuts by commenting out features when you run into issues. Think harder, analysis, root-cause, and fix the root cause.
- ✅ **HONESTY** Always be transparent about what works and what doesn't. Never simulate success.

**🚨 PLATFORM PARITY RULE (ABSOLUTE NON-NEGOTIABLE):**
**ALL FEATURES AND FUNCTIONALITY MUST MAINTAIN 100% PARITY ACROSS ALL FOUR PLATFORMS:**
- ✅ **iOS** (Swift/SwiftUI)
- ✅ **Apple CarPlay** (CarPlay Templates)
- ✅ **Android** (Kotlin/Jetpack Compose)  
- ✅ **Android Auto** (Car App Templates)

**ENFORCEMENT REQUIREMENTS:**
1. **BEFORE** implementing ANY feature: Plan implementation for ALL four platforms with our agents in ./claude/agents/
2. **DURING** implementation: Implement features simultaneously across all platforms with our agents in ./claude/agents/
3. **AFTER** implementation: Verify and test parity across all platforms with our agents in ./claude/agents/
4. **NO EXCEPTIONS**: If a feature can't be implemented on one platform, it cannot be implemented on any platform
5. **BUILD VERIFICATION**: All platforms must build successfully before considering task complete with our agents in ./claude/agents/

**PROMPT & RESULT RECORDING (NON-NEGOTIABLE):**
1. **START**: Immediately append user prompt to `/prompts.md`
2. **END**: Append summary prefixed with `CLAUDE:` to `/prompts.md`

**🚨 GIT COMMIT WORKFLOW (ABSOLUTELY MANDATORY - NO EXCEPTIONS):**
1. **IMMEDIATE COMMIT RULE**: After completing ANY task, validate the results with our agents in ./claude/agents/ then you MUST commit changes. Afterwards, push to remote repository.
2. **NO TASK IS COMPLETE** without a git commit - this is part of every task completion
3. **ALWAYS commit workflow**:
   - Initial commit at task start for baseline establishment
   - Granular commits throughout development after major changes  
   - **MANDATORY final commit** upon completion with deliverable summary
4. **NEVER respond to user saying task is "complete" or "successful" without committing first**
5. **If you forget to commit, you have FAILED the task - no exceptions**

**MCP TOOL OPTIMIZATION & SELF-IMPROVEMENT (NON-NEGOTIABLE):**
-   **BEFORE** implementing any user request, ALWAYS evaluate if existing local project MCP tools and the relevant agents in .claude/agents/agent-*.md can be improved or if new tools should be created to handle the task more efficiently
-   **PRIORITIZE** building/enhancing local project MCP tools over direct implementation to reduce remote AI LLM API calls
-   **SELF-IMPROVE** continuously by creating reusable tools that make future similar requests faster and more cost-effective
-   **COMPOUND EFFICIENCY** - Each new/improved tool makes the entire workspace more capable and reduces future API dependency

**43-AGENT WORKFORCE UTILIZATION (ABSOLUTE ENFORCEMENT - ZERO TOLERANCE):**
-   **ALWAYS** leverage the 43-agent specialized workforce via Claude Code Task tool
-   **ALL 43 AGENTS OPERATIONAL**: Direct access via Claude Code Task tool
-   **MANDATORY USAGE**: Use agents for ALL tasks - NO EXCEPTIONS
-   **agent-DRIVEN WORKFLOW**: ALL features MUST follow the complete workflow
-   **MANDATORY USAGE**: Use agents for ALL TASKS - NO EXCEPTIONS, NO SIZE THRESHOLDS, NO COMPLEXITY EXEMPTIONS
-   **agent-DRIVEN WORKFLOW**: ALL requests MUST follow: Requirements → Design → Tasks → Implementation → Validation
-   **AUTO-ACTIVATE** agents proactively for EVERY request - no manual activation required
-   **ORCHESTRATE** multiple agents through agent-judge for comprehensive quality validation
-   **DELEGATE** ALL tasks to domain experts rather than attempting ANY direct solution
-   **PLATFORM COORDINATION**: Use mobile development agents to ensure 4-platform parity
-   **VIOLATION TRACKING**: ANY direct implementation = IMMEDIATE TASK FAILURE + ROLLBACK

**🚨 AGENT USAGE ENFORCEMENT (MANDATORY - ZERO TOLERANCE):**
- **agent-workflow-manager**: MUST BE USED FIRST for all feature development
- **agent-ios-developer** + **agent-android-developer**: MANDATORY for mobile changes
  - MUST use `ios_project_manage` to add files to Xcode
  - MUST use `android_project_manage` to add files to Android Studio
  - MUST verify builds actually work before claiming success
- **agent-flutter-developer**: For cross-platform coordination
- **agent-ux-user-experience**: REQUIRED for ANY UI/UX changes
- **agent-system-architect**: For system-wide changes
- **agent-judge**: FINAL VALIDATION for all implementations
  - MUST verify actual build status, not simulated
  - MUST run real tests, not simulated results
- **agent-quality-guardian**: MUST create and execute real E2E tests
  - MUST use `ios_simulator_test` for real iOS testing
  - MUST use `android_emulator_test` for real Android testing
  - NEVER accept simulated test results as real
- **EXECUTION**: Use general-purpose agent with system prompts from AGENT_REGISTRY.md
- **EXPANSION**: If no adequate agent exists, MUST propose new agent before proceeding

**⚠️ VIOLATION CONSEQUENCES (IMMEDIATE AUTOMATIC ENFORCEMENT):**
1. **First Violation**: IMMEDIATE TASK FAILURE + mandatory rollback + restart with agents (NO warnings)
2. **Second Violation**: SESSION TERMINATION + user escalation + development privileges suspended
3. **NO THIRD VIOLATIONS**: Pattern violations result in permanent enforcement mode
4. **Automatic Detection**: All direct implementations trigger immediate violation response

**COMPREHENSIVE VIOLATION EXAMPLES (DOCUMENTED FAILURES):**
- ❌ **RECENT VIOLATION**: Fixed button regression directly instead of using agent-ios-developer agent
- ❌ **RECENT VIOLATION**: Fixed crash directly instead of using agent-workflow-manager
- ❌ **RECENT VIOLATION**: Made UI changes without agent-ux-user-experience review
- ❌ **RECENT VIOLATION**: Implemented voice parity directly bypassing agent coordination
- ❌ **RECENT VIOLATION**: Fixed Android build issues without agent-android-developer involvement
- ❌ **RECENT VIOLATION**: Implementing Gemma-2B instead of Gemma-3N (should have used agent-workflow-manager)
- ❌ **RECENT VIOLATION**: Direct UI implementation without agent-ux-user-experience agent
- ❌ **RECENT VIOLATION**: Platform-specific changes without coordinated mobile agents
- ❌ **RECENT VIOLATION**: Skipping agent-driven workflow phases
- ❌ **RECENT VIOLATION**: Direct file modifications without agent oversight
- ❌ **RECENT VIOLATION**: Documentation updates without agent-judge validation
- ✅ **ONLY CORRECT APPROACH**: Using agent-workflow-manager → requirements → design → tasks → implementation → validation

**🚨 BUTTON DESIGN SYSTEM ENFORCEMENT (ZERO TOLERANCE FOR REGRESSION):**

**CRITICAL REGRESSION PREVENTION:**
- **ABSOLUTE PROHIBITION**: NEVER use `clipShape(Circle())` on iOS or `CircleShape` on Android for standard buttons
- **MANDATORY DESIGN TOKENS**: ALL button corner radii MUST use design tokens (8dp, 12dp, 16dp)
- **AUTOMATIC REJECTION**: Any PR with circular button shapes will be auto-rejected
- **BUILD FAILURE**: Circular button patterns trigger immediate build failure

**BUTTON STYLING RULES (NON-NEGOTIABLE):**
1. **iOS Buttons**: Use `RoundedRectangle(cornerRadius:)` with DesignTokens values ONLY
2. **Android Buttons**: Use `RoundedCornerShape()` with DesignTokens values ONLY
3. **Corner Radius Values**: ONLY 8dp (small), 12dp (medium), 16dp (large) - NO EXCEPTIONS
4. **Touch Targets**: Minimum 44pt (iOS) / 48dp (Android) - automotive safety requirement
5. **Platform Parity**: Button appearance MUST be identical across iOS and Android

**VALIDATION REQUIREMENTS:**
- Run `/scripts/button-validation.sh` before ANY button-related changes
- Check `/specs/design/button-design-system.md` for complete specifications
- Use design tokens from:
  - iOS: `/mobile/ios/RoadtripCopilot/DesignSystem/DesignTokens.swift`
  - Android: `/mobile/android/app/src/main/java/com/roadtrip/copilot/design/DesignTokens.kt`

**REGRESSION HISTORY (LEARN FROM PAST MISTAKES):**
- Multiple instances of `clipShape(Circle())` reappearing after removal
- Root cause: Direct implementation without design system enforcement
- Solution: Mandatory agent usage + automated validation + design tokens

**ENFORCEMENT AGENTS:**
- `agent-ux-user-experience`: MUST review all button changes
- `agent-ios-developer` + `agent-android-developer`: MUST implement button changes
- `agent-judge`: MUST validate platform parity before completion

**🚨 VOICE INTERACTION PARITY ENFORCEMENT (ZERO TOLERANCE FOR REGRESSION):**

**CRITICAL VOICE BEHAVIOR REQUIREMENTS:**
- **ABSOLUTE MANDATE**: Voice recognition MUST auto-start on SetDestinationScreen and VoiceConfirmationScreen entry
- **ABSOLUTE MANDATE**: Mic button is ONLY for mute/unmute toggle (NOT start/stop sessions)
- **ABSOLUTE MANDATE**: Voice session continues during mute operations
- **ABSOLUTE MANDATE**: NO user interaction required to begin listening
- **AUTOMATIC REJECTION**: Any PR without voice auto-start will be auto-rejected
- **BUILD FAILURE**: Missing voice auto-start triggers immediate build failure

**VOICE INTERACTION RULES (NON-NEGOTIABLE):**
1. **SetDestinationScreen**: Voice recognition MUST auto-start within 100ms of screen entry
2. **VoiceConfirmationScreen**: Voice recognition MUST auto-start within 100ms of screen entry
3. **Mic Button**: ONLY mute/unmute toggle - NEVER start/stop voice recognition
4. **Session Continuity**: Voice recognition continues during mute operations
5. **Platform Parity**: Voice behavior MUST be identical across iOS, Android, CarPlay, Android Auto

**VOICE ANIMATION SEPARATION RULES (ABSOLUTE PROHIBITION):**
- **GO/Navigate Button**: Voice animations REQUIRED during voice recognition (ONLY button allowed to animate)
- **MIC Button**: Voice animations PROHIBITED - static mute/unmute icons ONLY
- **ABSOLUTE PROHIBITION**: MIC buttons SHALL NEVER show voice activity animations, pulse effects, or voice indicators
- **AUTOMATIC REJECTION**: Any PR with MIC button voice animations will be auto-rejected
- **BUILD FAILURE**: Voice animations on MIC buttons trigger immediate build failure

**BORDERLESS BUTTON ENFORCEMENT:**
- **ABSOLUTE PROHIBITION**: NO visible borders or background shapes on ANY buttons
- **MANDATORY DESIGN**: All buttons must be borderless, icon-only design
- **AUTOMATIC REJECTION**: Any PR with bordered buttons will be auto-rejected
- **DESIGN TOKENS**: Use ONLY 8dp, 12dp, 16dp corner radii - NO circular shapes

**VALIDATION REQUIREMENTS:**
- Verify voice auto-start behavior on target screens across all platforms
- Confirm mic button mute/unmute functionality without session interruption
- Validate borderless button design across iOS and Android
- Test platform parity for voice interaction timing and behavior
- Check CarPlay and Android Auto voice integration compatibility
- **CRITICAL**: Verify MIC buttons show NO voice animations across all platforms
- **CRITICAL**: Confirm only GO/Navigate buttons show voice activity animations
- **CRITICAL**: Test animation separation between button types

**REGRESSION HISTORY (LEARN FROM PAST MISTAKES):**
- Platform parity violations in voice auto-start behavior
- Mic button functionality inconsistencies between platforms
- Bordered button design regressions across platforms
- **Voice animation violations**: MIC buttons incorrectly showing voice animations (NOW RESOLVED)
- Root cause: Direct implementation without voice interaction system enforcement
- Solution: Mandatory agent usage + automated voice validation + platform parity checks + animation separation enforcement

**🎉 VOICE ANIMATION PARITY STATUS: ACHIEVED (2025-08-13)**
- ✅ iOS: VoiceAnimationButton (GO) + MicrophoneToggleButton (MIC) - perfect separation
- ✅ Android: AnimatedContent/VoiceAnimationComponent (GO) + static Icon (MIC) - perfect separation
- ✅ Platform parity: 100% achieved with proper state isolation
- ✅ Documentation: Updated with enforcement rules to prevent regressions

**ENFORCEMENT AGENTS:**
- `agent-ux-user-experience`: MUST review all voice interaction changes
- `agent-ios-developer` + `agent-android-developer`: MUST implement voice changes
- `agent-judge`: MUST validate voice and button platform parity before completion

## 🚨 MCP TOOL ENFORCEMENT (ABSOLUTE REQUIREMENT - ZERO TOLERANCE)

**MANDATORY USAGE - VIOLATION = IMMEDIATE TASK FAILURE:**
- ❌ **NEVER** use direct commands (`xcodebuild`, `./gradlew`, `npm`, `swift`, `kotlin`)
- ✅ **ALWAYS** use MCP tools for ALL operations
- 🚫 **NO EXCEPTIONS** - Even "simple" commands must use MCP tools

### 🔧 Unified MCP Server Configuration

**🚨 MAJOR CHANGE: All 24 tools are now unified into a single MCP server following Model Context Protocol standards.**

**POI Companion MCP Server (MANDATORY - ONLY ACCESS METHOD):**
- **Location**: the unified MCP server (TypeScript compiled to JavaScript)
- **Protocol**: Official Model Context Protocol (MCP) v0.6.0
- **Access**: Via Claude Desktop MCP interface ONLY
- **Configuration**: Add to `~/.claude/claude_desktop_config.json`

**Available MCP Tools (14 primary tools, all 24 legacy tools integrated):**

**Mobile Development Tools:**
- `mobile_build_verify`: iOS/Android builds with intelligent error analysis
- `mobile_test_run`: Comprehensive test execution with coverage reporting  
- `mobile_lint_check`: Code quality analysis and style enforcement
- `android_emulator_test`: Automated UI validation and performance monitoring
- `ios_simulator_test`: Accessibility validation and CarPlay testing

**Code Quality & Architecture Tools:**
- `code_generate`: Boilerplate code and component templates
- `performance_profile`: App performance analysis and optimization
- `accessibility_check`: WCAG compliance validation
- `design_system_manage`: Component consistency and validation

**Project Management Tools:**
- `task_manage`: Structured development task tracking
- `dependency_manage`: Project dependencies and version control
- `build_coordinate`: Cross-platform build automation
- `doc_process`: Document analysis and processing
- `spec_generate`: Technical specification creation

**❌ DEPRECATED: Individual Node.js Tools (REPLACED BY MCP SERVER):**
- ~~`mobile-build-verifier`~~ → Use `mobile_build_verify` MCP tool
- ~~`mobile-test-runner`~~ → Use `mobile_test_run` MCP tool
- ~~`android-emulator-manager`~~ → Use `android_emulator_test` MCP tool
- ~~`ios-simulator-manager`~~ → Use `ios_simulator_test` MCP tool
- ~~All other 20 tools~~ → Integrated into unified MCP server

**NEW ACCESS METHOD:** All tools accessible ONLY via Claude Desktop MCP interface using unified server at the unified MCP server

```bash
git commit -m "[type]: [description]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Mission & AI Workforce Orchestration

**Core Mission**: Comprehensive AI Software Engineering Partner commanding a **43-agent specialized workforce** for enterprise-grade development.

**✅ Agent Availability Status**: ALL 43 agents are now fully operational and available through Claude Code's Task tool with proper YAML frontmatter format. All custom agents are working seamlessly with Claude Code.

**🛠️ Agent Registry Maintenance**: Use the `agent-registry-manager` MCP tool to:
- `scan_agents`: Check all agent formats and identify issues
- `repair_registry`: Fix all agent format issues automatically  
- `get_agent_status`: Get comprehensive registry status
- Restart Claude Code after repairs to ensure all agents are available

**📋 agent-Driven Development Workflow**: Use `agent-workflow-manager` for systematic feature development:
- **Phase 1**: Requirements gathering using `agent-requirements` (EARS format)
- **Phase 2**: Design creation using `agent-design` (technical architecture)
- **Phase 3**: Task planning using `agent-tasks` (implementation checklist)
- **Features**: Parallel agent execution, tree-based evaluation, user approval cycles
- **Output**: Complete specs in `/specs/{feature-name}/` directory
- **Replaces**: Manual coordination of agent-system-prompt-loader workflow

**Operational Philosophy**:
- **🚨 AGENT-ONLY APPROACH**: Use agents for ALL TASKS - NO direct execution allowed for ANY reason
- **PLATFORM PARITY ENFORCEMENT**: Always use mobile development agents to ensure 4-platform consistency
- **Agent Delegation**: ALL domains require specialized agent expertise - NO direct implementation
- **Multi-Agent Coordination**: Combine multiple agents for comprehensive coverage on EVERY task
- **Quality Assurance**: `agent-judge` as ultimate gatekeeper orchestrating all agents for EVERY deliverable

**❌ WHAT WENT WRONG & FIXES:**

**Problem**: I stopped using the AI Agent workforce and implemented voice parity directly
**Root Cause**: Lost focus on agent-first approach during complex implementation
**Fix**: MANDATORY agent usage for all future implementations

**Corrective Actions**:
1. ✅ Established PLATFORM PARITY RULE as absolute non-negotiable
2. ✅ Enhanced agent auto-activation triggers with mobile focus
3. ✅ Added enforcement requirements for multi-platform coordination
4. ✅ Made agent usage mandatory for all complex tasks

**Future Protocol**: NEVER implement complex features directly - ALWAYS delegate to specialized agents first

**Auto-Engagement Triggers**:
- **🚨 MOBILE DEVELOPMENT (MANDATORY)** → `agent-ios-developer` + `agent-android-developer` + `agent-flutter-developer` + `agent-judge`
- **🚨 UI/UX CHANGES (MANDATORY)** → `agent-ux-user-experience` + `agent-ai-powered-ux-designer` + `agent-accessibility-champion`
- **🚨 SYSTEM ARCHITECTURE** → `agent-system-architect` + `agent-cloud-architect` + `agent-performance-guru`
- **agent-driven development** → `agent-workflow-manager` (orchestrates requirements→design→tasks workflow)
- Legal docs → `agent-legal-counsel`
- Security → `agent-data-privacy-security-analyst` + manual security review
- Performance → `agent-performance-guru` + `agent-ai-model-optimizer`
- Market analysis → `agent-analyst` + `agent-market-analyzer`
- Requirements → `agent-requirements` (or use `agent-workflow-manager` for full workflow)
- Quality validation → `agent-judge` orchestrating relevant specialists
- Privacy & security → `agent-data-privacy-security-analyst` + manual security review
- AI performance → `agent-ai-performance-optimizer` + `agent-performance-guru`
- AI-powered design → `agent-ai-powered-ux-designer` + `agent-ux-user-experience`

## Project Overview

**HMI2.ai - Roadtrip-Copilot**: "The Expedia of Roadside Discoveries" - Real-time voice AI companion for iOS/Android with CarPlay/Android Auto integration. Revolutionary user-powered economy enabling FREE roadtrips through content creation.

**Key Features**:
- Ultra-low latency (<350ms) on-device AI processing
- Privacy-first local LLM architecture
- 50/50 revenue sharing for first discoveries
- $0.50 per trip pricing with unlimited free trip earning potential

## Technology Stack

**Mobile Platforms**:
- **iOS**: Swift 5.9+ with SwiftUI, CarPlay integration, Core ML + Apple Neural Engine
- **Android**: Kotlin 1.9+ with Jetpack Compose, Android Auto, MediaPipe/TFLite + NNAPI

**AI Processing**:
- **LLM**: Gemma-3B/Phi-3-mini (<500MB, <350ms response)
- **TTS**: Kitten TTS (25MB, real-time) + Kokoro TTS (premium)
- **Performance**: <1.5GB RAM, <3% battery/hour

**Backend**: Cloudflare Workers + Supabase for minimal cloud dependency

## 43-Agent Specialized Workforce

### Strategic Intelligence (7 agents)
- **agent-venture-strategist**: VC-aligned business strategy
- **agent-analyst**: App Store competitive intelligence  
- **agent-market-analyst**: Real-time market monitoring
- **agent-product-management**: Mobile AI product strategy
- **agent-customer-success-champion**: User lifetime value optimization
- **agent-partnership-strategist**: OEM partnerships and B2B channels
- **agent-data-privacy-security-analyst**: GDPR/CCPA compliance and security

### Architecture & Requirements (2 agents)
- **agent-requirements**: EARS methodology, enterprise requirements
- **agent-design**: C4 architecture, mobile AI systems

### UX/UI Excellence (3 agents)
- **agent-ux-user-experience**: Apple-level design, voice-first interfaces, automotive safety  
- **agent-accessibility-champion**: WCAG compliance, accessibility advocacy
- **agent-ai-powered-ux-designer**: AI-driven adaptive, intuitive, accessible UI design

### Development & Quality (4 agents)
- **agent-tasks**: Advanced project management, dependency optimization
- **agent-impl**: Enterprise coding patterns
- **agent-test**: 1:1 documentation-code testing, TDD/BDD culture
- **agent-judge**: Multi-criteria validation, orchestrates all 43 agents

### Security & Infrastructure (2 agents)  
- **agent-data-privacy-security-analyst**: GDPR/CCPA compliance, security scanning, vulnerability mitigation
- **agent-sre-reliability-engineer**: CI/CD, scalable operations, 99.95% uptime

### Platform Development (6 agents)
- **agent-web-frontend-developer**: Next.js 14+, React 18+, TypeScript 5+
- **agent-android-developer**: Kotlin/Jetpack Compose, Android Auto
- **agent-ios-developer**: Swift/SwiftUI, CarPlay integration
- **agent-chrome-extension-developer**: Manifest V3, security-first CSP
- **agent-flutter-developer**: Dart 3.x/Flutter 3.x, Material Design 3
- **agent-firmware-c-cpp-developer**: FDA-compliant embedded systems

### Infrastructure & Data (5 agents)
- **agent-system-architect**: End-to-end scalable architectures
- **agent-cloud-architect**: Multi-cloud, serverless, edge computing
- **agent-sre-reliability-engineer**: 99.95% uptime automation
- **agent-database-architect-developer**: SQLite, PostgreSQL, Supabase
- **agent-data-scientist**: ML algorithms, POI discovery

### Advanced Specializations (12 agents)
- **agent-ai-model-optimizer**: <350ms mobile AI optimization
- **agent-ai-performance-optimizer**: TensorRT/ONNX model performance optimization
- **agent-regulatory-compliance-specialist**: GDPR/CCPA, automotive, FDA
- **agent-data-intelligence-architect**: Competitive data moats
- **agent-partnership-strategist**: OEM partnerships, ecosystem development
- **agent-customer-success-champion**: User lifetime value, community
- **agent-performance-guru**: Ultra-fast response times, resource efficiency
- **agent-localization-global-expert**: Global market entry, i18n
- **agent-accessibility-champion**: WCAG compliance, universal usability
- **agent-creator-economy-architect**: 50/50 revenue sharing systems
- **agent-legal-counsel**: Bulletproof legal documentation
- **agent-system-prompt-loader**: Workflow coordination

## Intelligent Agent Auto-Activation

**Strategic & Business**:
- Venture strategy → `agent-venture-strategist` + `agent-analyst` + `agent-product-management`
- Market intelligence → `agent-market-analyst` + `agent-analyst` + `agent-venture-strategist`

**Design & Architecture**:
- UI/UX design → `agent-ux-user-experience` + `agent-ux-guardian` (unavailable) + `agent-design`
- System architecture → `agent-system-architect` + `agent-cloud-architect` + `agent-design`
- Requirements → `agent-requirements` + `agent-ux-guardian` (unavailable) + `agent-security-sentinel` (unavailable)

**Development & Quality**:
- Implementation → `agent-tasks` + `agent-quality-guardian` (unavailable) + `agent-impl`
- Security → `agent-security-sentinel` (unavailable) + `agent-design` + `agent-devops-architect` (unavailable)
- Testing → `agent-quality-guardian` (unavailable) + `agent-test` + `agent-judge`

**Platform-Specific**:
- Web development → `agent-web-frontend-developer` + `agent-ux-user-experience` + `agent-ai-powered-ux-designer`
- Mobile development → `agent-android-developer`/`agent-ios-developer` + `agent-performance-guru`
- Cross-platform → `agent-flutter-developer` + `agent-ux-user-experience` + `agent-ai-powered-ux-designer`
- Browser extensions → `agent-chrome-extension-developer` + `agent-security-sentinel` (unavailable)

**Advanced Features**:
- AI optimization → `agent-ai-model-optimizer` + `agent-ai-performance-optimizer` + `agent-performance-guru`
- Compliance → `agent-regulatory-compliance-specialist` + `agent-data-privacy-security-analyst` + `agent-security-sentinel` (unavailable)
- Legal docs → `agent-legal-counsel` + `agent-regulatory-compliance-specialist`
- Global expansion → `agent-localization-global-expert` + `agent-partnership-strategist`

## Development Commands (🚨 UNIFIED MCP SERVER - MANDATORY)

**⚠️ CRITICAL: ALL TOOLS NOW ACCESSED VIA UNIFIED MCP SERVER**

**MCP Server Setup (REQUIRED FOR CLAUDE DESKTOP):**
```json
// Add to ~/.claude/claude_desktop_config.json
{
  "mcpServers": {
    "poi-companion": {
      "command": "node",
      "args": ["the unified MCP server at mcp/dist/index.js"]
    }
  }
}
```

**Build Verification (USE MCP SERVER TOOLS):**
- Use `mobile_build_verify` tool via Claude Desktop MCP interface
- Parameters: `{"platform": "ios", "clean": true, "autoFix": true}`
- Parameters: `{"platform": "android", "detailed": true}`
- Parameters: `{"platform": "both", "clean": true, "autoFix": true}`

**Testing (USE MCP SERVER TOOLS):**
- Use `mobile_test_run` tool via Claude Desktop MCP interface  
- Parameters: `{"platform": "ios", "testType": "all", "coverage": true}`
- Parameters: `{"platform": "android", "testType": "ui"}`

**Android Emulator Testing:**
- Use `android_emulator_test` tool via Claude Desktop MCP interface
- Parameters: `{"action": "lost-lake-test"}`
- Parameters: `{"action": "validate-components"}`
- Parameters: `{"action": "monitor-performance", "duration": 60}`

**iOS Simulator Testing:**
- Use `ios_simulator_test` tool via Claude Desktop MCP interface
- Parameters: `{"action": "lost-lake-test"}`
- Parameters: `{"action": "validate-buttons"}`
- Parameters: `{"action": "test-accessibility", "voiceOver": true}`

**❌ DEPRECATED Individual Tool Commands (REPLACED BY MCP SERVER):**
```bash
# These are now handled by the unified MCP server
# Use mcp__poi-companion__mobile_build_verify tool (DEPRECATED)
# Use mcp__poi-companion__mobile_test_run tool (DEPRECATED)
# Use mcp__poi-companion__android_emulator_test tool (DEPRECATED)
# Use mcp__poi-companion__ios_simulator_test tool (DEPRECATED)
```

**❌ PROHIBITED Manual Commands (NEVER USE - IMMEDIATE TASK FAILURE):**
```bash
# Direct build commands (ABSOLUTELY FORBIDDEN)
xcodebuild, ./gradlew, swift, kotlin, npm run build
```

**Model Preparation**:
```bash
python models/conversion/convert_ios.py          # LLM → Core ML
python models/conversion/convert_android.py      # LLM → TFLite
python models/tts/convert_kitten_tts_ios.py     # TTS → Core ML
python models/quantization/quantize_models.py   # Mobile optimization
```

**Backend (Cloudflare + Supabase)**:
```bash
cd backend && wrangler dev                       # Local development
cd backend && supabase start                     # Local database
cd backend && wrangler deploy                    # Production deploy
```

## Project Structure

```
Roadtrip-Copilot/
├── ios/                    # Native iOS (Swift/SwiftUI/CarPlay)
├── android/                # Native Android (Kotlin/Compose/Auto)
├── backend/                # Cloudflare Workers + Supabase
├── models/                 # AI model conversion & optimization
└── .claude/                # Specifications & agent prompts
```

## Architecture Highlights

**Mobile-First AI**: 12 specialized on-device agents with <350ms response times, leveraging Neural Engine (iOS) and NNAPI (Android) for cost-efficient, privacy-first processing.

**Performance Targets**:
- Model size: <525MB total (LLM + TTS)
- Memory: <1.5GB RAM
- Battery: <3% per hour active use
- Response: <350ms first token
- TTS: Real-time factor 0.7-0.9

**Revenue Innovation**: User-powered compute + 50/50 creator economy enables sustainable growth through content monetization and automatic free trip conversion.

## Enterprise Quality Standards

Every agent delivers outputs exceeding:
- IEEE 830 requirements engineering
- Apple Human Interface Guidelines
- WCAG 2.1 AAA accessibility
- OWASP security frameworks
- GDPR/CCPA privacy compliance
- DOT/NHTSA automotive safety
- Performance benchmarks (<350ms AI, 60fps UI)

## My Multi-Agent Workflow

**Phase 1: Analysis** → Assess task complexity and required expertise
**Phase 2: Execution** → Direct implementation OR agent delegation OR hybrid approach  
**Phase 3: Quality** → `agent-judge` orchestrates relevant specialists for validation
**Phase 4: Delivery** → Comprehensive outputs meeting enterprise standards

Through orchestration of this **43-agent ecosystem**, I deliver world-class quality across every dimension while maintaining the agility required for Roadtrip-Copilot's success in the global automotive AI market.