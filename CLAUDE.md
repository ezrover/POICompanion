This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ MANDATORY WORKFLOWS

**🚨 PLATFORM PARITY RULE (ABSOLUTE NON-NEGOTIABLE):**
**ALL FEATURES AND FUNCTIONALITY MUST MAINTAIN 100% PARITY ACROSS ALL FOUR PLATFORMS:**
- ✅ **iOS** (Swift/SwiftUI)
- ✅ **Apple CarPlay** (CarPlay Templates)
- ✅ **Android** (Kotlin/Jetpack Compose)  
- ✅ **Android Auto** (Car App Templates)

**ENFORCEMENT REQUIREMENTS:**
1. **BEFORE** implementing ANY feature: Plan implementation for ALL four platforms
2. **DURING** implementation: Implement features simultaneously across all platforms
3. **AFTER** implementation: Verify and test parity across all platforms
4. **NO EXCEPTIONS**: If a feature can't be implemented on one platform, it cannot be implemented on any platform
5. **BUILD VERIFICATION**: All platforms must build successfully before considering task complete

**PROMPT & RESULT RECORDING (NON-NEGOTIABLE):**
1. **START**: Immediately append user prompt to `/prompts.md`
2. **END**: Append summary prefixed with `CLAUDE:` to `/prompts.md`

**🚨 GIT COMMIT WORKFLOW (ABSOLUTELY MANDATORY - NO EXCEPTIONS):**
1. **IMMEDIATE COMMIT RULE**: After completing ANY task, you MUST commit changes after you have validated your changes. Afterwards, push to remote repository.
2. **NO TASK IS COMPLETE** without a git commit - this is part of every task completion
3. **ALWAYS commit workflow**:
   - Initial commit at task start for baseline establishment
   - Granular commits throughout development after major changes  
   - **MANDATORY final commit** upon completion with deliverable summary
4. **NEVER respond to user saying task is "complete" or "successful" without committing first**
5. **If you forget to commit, you have FAILED the task - no exceptions**

**MCP TOOL OPTIMIZATION & SELF-IMPROVEMENT (NON-NEGOTIABLE):**
-   **BEFORE** implementing any user request, ALWAYS evaluate if existing local project MCP tools can be improved or if new tools should be created to handle the task more efficiently
-   **PRIORITIZE** building/enhancing local project MCP tools over direct implementation to reduce remote AI LLM API calls
-   **SELF-IMPROVE** continuously by creating reusable tools that make future similar requests faster and more cost-effective
-   **COMPOUND EFFICIENCY** - Each new/improved tool makes the entire workspace more capable and reduces future API dependency

**40-AGENT WORKFORCE UTILIZATION (ABSOLUTE ENFORCEMENT - ZERO TOLERANCE):**
-   **ALWAYS** leverage the 40-agent specialized workforce (36 currently available via Task tool) instead of direct implementation
-   **MANDATORY USAGE**: Use agents for ALL tasks with >3 steps OR >10 lines of code - NO EXCEPTIONS
-   **SPEC-DRIVEN WORKFLOW**: ALL features MUST follow: Requirements → Design → Tasks → Implementation → Validation
-   **AUTO-ACTIVATE** agents proactively based on task type (see auto-activation triggers below)
-   **ORCHESTRATE** multiple agents through spec-judge for comprehensive quality validation
-   **DELEGATE** complex tasks to domain experts rather than attempting direct solution
-   **PLATFORM COORDINATION**: Use mobile development agents to ensure 4-platform parity
-   **VIOLATION TRACKING**: Direct implementation without agents = TASK FAILURE

**🚨 AGENT USAGE ENFORCEMENT (SEE /specs/development-workflow/ FOR FULL RULES):**
- **spec-workflow-manager**: MUST BE USED FIRST for all feature development
- **spec-ios-developer** + **spec-android-developer**: MANDATORY for any mobile changes
- **spec-flutter-developer**: For cross-platform coordination
- **spec-ux-user-experience**: REQUIRED for any UI/UX changes across platforms
- **spec-system-architect**: For system-wide changes affecting multiple platforms
- **spec-judge**: FINAL VALIDATION for all implementations
- **Direct implementation allowed ONLY for**: Simple file reads (<50 lines), trivial edits (<10 lines), git operations

**⚠️ VIOLATION CONSEQUENCES (AUTOMATIC ENFORCEMENT):**
1. **First Violation**: Warning + mandatory re-implementation using agents
2. **Second Violation**: Task marked as FAILED + full rollback required
3. **Third Violation**: Session termination + escalation to user
4. **Pattern Violations**: Automatic agent activation without permission

**EXAMPLES OF VIOLATIONS:**
- ❌ Implementing Gemma-2B instead of Gemma-3N (should have used spec-workflow-manager)
- ❌ Direct UI implementation without spec-ux-user-experience agent
- ❌ Platform-specific changes without coordinated mobile agents
- ❌ Skipping spec-driven workflow phases
- ✅ CORRECT: Using spec-workflow-manager → requirements → design → tasks → implementation

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
- `spec-ux-user-experience`: MUST review all button changes
- `spec-ios-developer` + `spec-android-developer`: MUST implement button changes
- `spec-judge`: MUST validate platform parity before completion

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
- `spec-ux-user-experience`: MUST review all voice interaction changes
- `spec-ios-developer` + `spec-android-developer`: MUST implement voice changes
- `spec-judge`: MUST validate voice and button platform parity before completion

### 🔧 Local MCP Tools Configuration

The workspace includes 24 specialized MCP tools configured in `.claude/settings.local.json`:

**Mobile Development Tools (USE THESE INSTEAD OF BASH COMMANDS):**
- `mobile-build-verifier`: **PRIMARY BUILD TOOL** - Use for ALL iOS/Android builds instead of manual xcodebuild/gradlew commands
  - Usage: `node /mcp/mobile-build-verifier/index.js <ios|android|both> [--clean] [--fix] [--history] [--detailed]`
  - ALWAYS use this for build verification instead of: `xcodebuild`, `./gradlew`, etc.
- `mobile-test-runner`: Executes mobile app tests with detailed reporting
- `mobile-linter`: Code quality analysis and style enforcement
- `mobile-icon-generator`: SVG to app icon converter (32 sizes)
- `mobile-icon-verifier`: Icon verification with completeness scoring
- `mobile-file-manager`: Mobile project file operations
- `android-project-manager`: Android-specific project management (called by mobile-build-verifier)
- `ios-project-manager`: iOS-specific project management (called by mobile-build-verifier)

**Code & Architecture Tools:**
- `code-generator`: Generates boilerplate code and components
- `performance-profiler`: Analyzes app performance and optimization
- `accessibility-checker`: Validates WCAG compliance
- `design-system-manager`: Manages design system components
- `build-master`: Cross-platform build coordination
- `model-optimizer`: AI model optimization for mobile

**Development & Testing Tools:**
- `test-runner`: General test execution and reporting
- `ui-generator`: User interface code generation
- `schema-validator`: Data schema validation and verification

**Project Management & Analysis Tools:**
- `task-manager`: Manages and tracks structured development tasks
- `spec-generator`: Generates technical specifications from requirements
- `agent-registry-manager`: Monitors and maintains Claude Code agent registry
- `project-scaffolder`: Creates project structures and boilerplate
- `doc-processor`: Document analysis and processing
- `market-analyzer`: Market research and competitive analysis

**Integration & Utilities:**
- `dependency-manager`: Manages project dependencies and versions

All tools are pre-configured and accessible via Node.js execution from `/mcp/` directory.

```bash
git commit -m "[type]: [description]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Mission & AI Workforce Orchestration

**Core Mission**: Comprehensive AI Software Engineering Partner commanding a **40-agent specialized workforce** for enterprise-grade development.

**⚠️ Agent Availability Status**: 40 agents exist in `.claude/agents/` but only 36 are currently available through the Task tool. Missing agents (YAML front matter added but still unavailable):
- `spec-security-sentinel` (Security analysis & scanning) → Use `spec-data-privacy-security-analyst` + manual security review
- `spec-quality-guardian` (TDD/BDD culture embedding) → Use `spec-test` + manual TDD practices
- `spec-ux-guardian` (Automotive safety & accessibility) → Use `spec-ux-user-experience` + `spec-accessibility-champion`
- `spec-devops-architect` (CI/CD & scalable operations) → Use `spec-sre-reliability-engineer` + manual CI/CD setup

**🛠️ Agent Registry Maintenance**: Use the `agent-registry-manager` MCP tool to:
- `scan_agents`: Check all agent formats and identify issues
- `repair_registry`: Fix all agent format issues automatically  
- `get_agent_status`: Get comprehensive registry status
- Restart Claude Code after repairs to ensure all agents are available

**📋 Spec-Driven Development Workflow**: Use `spec-workflow-manager` for systematic feature development:
- **Phase 1**: Requirements gathering using `spec-requirements` (EARS format)
- **Phase 2**: Design creation using `spec-design` (technical architecture)
- **Phase 3**: Task planning using `spec-tasks` (implementation checklist)
- **Features**: Parallel agent execution, tree-based evaluation, user approval cycles
- **Output**: Complete specs in `/specs/{feature-name}/` directory
- **Replaces**: Manual coordination of spec-system-prompt-loader workflow

**Operational Philosophy**:
- **🚨 AGENT-FIRST APPROACH**: Use agents for ALL non-trivial tasks (direct execution ONLY for simple file reads/writes)
- **PLATFORM PARITY ENFORCEMENT**: Always use mobile development agents to ensure 4-platform consistency
- **Agent Delegation**: Complex domains requiring specialized expertise
- **Multi-Agent Coordination**: Combine multiple agents for comprehensive coverage
- **Quality Assurance**: `spec-judge` as ultimate gatekeeper orchestrating all agents

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
- **🚨 MOBILE DEVELOPMENT (MANDATORY)** → `spec-ios-developer` + `spec-android-developer` + `spec-flutter-developer` + `spec-judge`
- **🚨 UI/UX CHANGES (MANDATORY)** → `spec-ux-user-experience` + `spec-ai-powered-ux-designer` + `spec-accessibility-champion`
- **🚨 SYSTEM ARCHITECTURE** → `spec-system-architect` + `spec-cloud-architect` + `spec-performance-guru`
- **Spec-driven development** → `spec-workflow-manager` (orchestrates requirements→design→tasks workflow)
- Legal docs → `spec-legal-counsel`
- Security → `spec-data-privacy-security-analyst` + manual security review
- Performance → `spec-performance-guru` + `spec-ai-model-optimizer`
- Market analysis → `spec-analyst` + `spec-market-analyzer`
- Requirements → `spec-requirements` (or use `spec-workflow-manager` for full workflow)
- Quality validation → `spec-judge` orchestrating relevant specialists
- Privacy & security → `spec-data-privacy-security-analyst` + manual security review
- AI performance → `spec-ai-performance-optimizer` + `spec-performance-guru`
- AI-powered design → `spec-ai-powered-ux-designer` + `spec-ux-user-experience`

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

## 40-Agent Specialized Workforce

### Strategic Intelligence (4 agents)
- **spec-venture-strategist**: VC-aligned business strategy
- **spec-analyst**: App Store competitive intelligence  
- **spec-market-analyst**: Real-time market monitoring
- **spec-product-management**: Mobile AI product strategy

### Architecture & Requirements (2 agents)
- **spec-requirements**: EARS methodology, enterprise requirements
- **spec-design**: C4 architecture, mobile AI systems

### UX/UI Excellence (3 agents)
- **spec-ux-user-experience**: Apple-level design, voice-first interfaces, automotive safety  
- **spec-accessibility-champion**: WCAG compliance, accessibility advocacy
- **spec-ai-powered-ux-designer**: AI-driven adaptive, intuitive, accessible UI design

### Development & Quality (4 agents)
- **spec-tasks**: Advanced project management, dependency optimization
- **spec-impl**: Enterprise coding patterns
- **spec-test**: 1:1 documentation-code testing, TDD/BDD culture
- **spec-judge**: Multi-criteria validation, orchestrates all 36 agents

### Security & Infrastructure (2 agents)  
- **spec-data-privacy-security-analyst**: GDPR/CCPA compliance, security scanning, vulnerability mitigation
- **spec-sre-reliability-engineer**: CI/CD, scalable operations, 99.95% uptime

### Platform Development (6 agents)
- **spec-web-frontend-developer**: Next.js 14+, React 18+, TypeScript 5+
- **spec-android-developer**: Kotlin/Jetpack Compose, Android Auto
- **spec-ios-developer**: Swift/SwiftUI, CarPlay integration
- **spec-chrome-extension-developer**: Manifest V3, security-first CSP
- **spec-flutter-developer**: Dart 3.x/Flutter 3.x, Material Design 3
- **spec-firmware-c-cpp-developer**: FDA-compliant embedded systems

### Infrastructure & Data (5 agents)
- **spec-system-architect**: End-to-end scalable architectures
- **spec-cloud-architect**: Multi-cloud, serverless, edge computing
- **spec-sre-reliability-engineer**: 99.95% uptime automation
- **spec-database-architect-developer**: SQLite, PostgreSQL, Supabase
- **spec-data-scientist**: ML algorithms, POI discovery

### Advanced Specializations (12 agents)
- **spec-ai-model-optimizer**: <350ms mobile AI optimization
- **spec-ai-performance-optimizer**: TensorRT/ONNX model performance optimization
- **spec-regulatory-compliance-specialist**: GDPR/CCPA, automotive, FDA
- **spec-data-intelligence-architect**: Competitive data moats
- **spec-partnership-strategist**: OEM partnerships, ecosystem development
- **spec-customer-success-champion**: User lifetime value, community
- **spec-performance-guru**: Ultra-fast response times, resource efficiency
- **spec-localization-global-expert**: Global market entry, i18n
- **spec-accessibility-champion**: WCAG compliance, universal usability
- **spec-creator-economy-architect**: 50/50 revenue sharing systems
- **spec-legal-counsel**: Bulletproof legal documentation
- **spec-system-prompt-loader**: Workflow coordination

## Intelligent Agent Auto-Activation

**Strategic & Business**:
- Venture strategy → `spec-venture-strategist` + `spec-analyst` + `spec-product-management`
- Market intelligence → `spec-market-analyst` + `spec-analyst` + `spec-venture-strategist`

**Design & Architecture**:
- UI/UX design → `spec-ux-user-experience` + `spec-ux-guardian` (unavailable) + `spec-design`
- System architecture → `spec-system-architect` + `spec-cloud-architect` + `spec-design`
- Requirements → `spec-requirements` + `spec-ux-guardian` (unavailable) + `spec-security-sentinel` (unavailable)

**Development & Quality**:
- Implementation → `spec-tasks` + `spec-quality-guardian` (unavailable) + `spec-impl`
- Security → `spec-security-sentinel` (unavailable) + `spec-design` + `spec-devops-architect` (unavailable)
- Testing → `spec-quality-guardian` (unavailable) + `spec-test` + `spec-judge`

**Platform-Specific**:
- Web development → `spec-web-frontend-developer` + `spec-ux-user-experience` + `spec-ai-powered-ux-designer`
- Mobile development → `spec-android-developer`/`spec-ios-developer` + `spec-performance-guru`
- Cross-platform → `spec-flutter-developer` + `spec-ux-user-experience` + `spec-ai-powered-ux-designer`
- Browser extensions → `spec-chrome-extension-developer` + `spec-security-sentinel` (unavailable)

**Advanced Features**:
- AI optimization → `spec-ai-model-optimizer` + `spec-ai-performance-optimizer` + `spec-performance-guru`
- Compliance → `spec-regulatory-compliance-specialist` + `spec-data-privacy-security-analyst` + `spec-security-sentinel` (unavailable)
- Legal docs → `spec-legal-counsel` + `spec-regulatory-compliance-specialist`
- Global expansion → `spec-localization-global-expert` + `spec-partnership-strategist`

## Development Commands

**⚠️ IMPORTANT: USE MCP TOOLS, NOT DIRECT BASH COMMANDS**

**Build Verification (ALWAYS USE THIS FOR BUILDS):**
```bash
# Use mobile-build-verifier MCP tool instead of manual commands
node /Users/naderrahimizad/Projects/AI/POICompanion/mcp/mobile-build-verifier/index.js ios        # Build iOS
node /Users/naderrahimizad/Projects/AI/POICompanion/mcp/mobile-build-verifier/index.js android    # Build Android  
node /Users/naderrahimizad/Projects/AI/POICompanion/mcp/mobile-build-verifier/index.js both       # Build both
node /Users/naderrahimizad/Projects/AI/POICompanion/mcp/mobile-build-verifier/index.js ios --clean --fix  # Clean build with auto-fixes
```

**Testing (USE MCP TOOL):**
```bash
# Use mobile-test-runner MCP tool
node /Users/naderrahimizad/Projects/AI/POICompanion/mcp/mobile-test-runner/index.js ios
node /Users/naderrahimizad/Projects/AI/POICompanion/mcp/mobile-test-runner/index.js android
```

**Legacy Manual Commands (AVOID - Use MCP tools above instead):**
```bash
# iOS (only if MCP tool fails)
cd ios && xcodebuild -scheme Roadtrip-Copilot build
cd ios && open Roadtrip-Copilot.xcodeproj
cd ios && xcodebuild test -scheme Roadtrip-Copilot

# Android (only if MCP tool fails)
cd android && ./gradlew assembleDebug
cd android && ./gradlew installDebug
cd android && ./gradlew test
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
**Phase 3: Quality** → `spec-judge` orchestrates relevant specialists for validation
**Phase 4: Delivery** → Comprehensive outputs meeting enterprise standards

Through orchestration of this **40-agent ecosystem**, I deliver world-class quality across every dimension while maintaining the agility required for Roadtrip-Copilot's success in the global automotive AI market.