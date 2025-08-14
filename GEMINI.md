# Gemini Project Guidance

This file provides guidance for the Gemini AI assistant when working in this repository.

## ⚠️ MANDATORY WORKFLOWS

**PROMPT & RESULT RECORDING (NON-NEGOTIABLE):**
1.  **START**: Immediately append user prompt to `prompts.md`.
2.  **END**: Append a summary prefixed with `GEMINI:` to `prompts.md`.

**GIT COMMIT WORKFLOW (NON-NEGOTIABLE):**
1.  **Initial Commit**: Start any new task with an initial commit to establish a baseline.
2.  **Granular Commits**: Make small, frequent commits after each logical change.
3.  **Final Commit**: Upon task completion, make a final commit summarizing the work.
4.  **My Changes Only**: When committing, only include changes made by me.

**MCP TOOL OPTIMIZATION & SELF-IMPROVEMENT (NON-NEGOTIABLE):**
-   **BEFORE** implementing any user request, ALWAYS evaluate if existing MCP tools can be improved or if new tools should be created to handle the task more efficiently
-   **PRIORITIZE** building/enhancing local MCP tools over direct implementation to reduce remote AI LLM API calls
-   **SELF-IMPROVE** continuously by creating reusable tools that make future similar requests faster and more cost-effective
-   **COMPOUND EFFICIENCY** - Each new/improved tool makes the entire workspace more capable and reduces future API dependency

### 🔧 Local MCP Tools Configuration

The workspace includes 10 specialized MCP tools configured in `.claude/settings.local.json`:

**Development Tools:**
- `mobile-build-verifier`: Automates iOS/Android compilation checks
- `mobile-test-runner`: Executes mobile app tests with detailed reporting
- `mobile-linter`: Code quality analysis and style enforcement
- `dependency-manager`: Manages project dependencies and versions

**Code & Architecture Tools:**
- `code-generator`: Generates boilerplate code and components
- `performance-profiler`: Analyzes app performance and optimization
- `accessibility-checker`: Validates WCAG compliance
- `design-system-manager`: Manages design system components

**Project Management Tools:**
- `task-manager`: Manages and tracks structured development tasks
- `spec-generator`: Generates technical specifications from requirements

All tools are now unified in a single MCP server accessible via Claude Code MCP interface. Use mcp__poi-companion__* tools instead of direct node commands.

**Commit Message Format:**
```bash
# Initial commit at task start
git add -A
git commit -m "feat: initialize [task-name] - establish baseline for [feature-description]"

# Granular commits throughout development
git add [changed-files]
git commit -m "[type]: [specific-change-description]"

# Final commit upon completion
git add -A
git commit -m "[type]: complete [task-name] - [summary-of-deliverables]"
```

## 🤖 40-Agent Specialized Workforce

This project uses a 40-agent specialized workforce. Detailed specifications for each agent are in the `.claude/agents/` directory.

**Key Agent Categories**:
- Strategic Intelligence (4)
- Architecture & Requirements (2)
- UX/UI Excellence (3)
- Development & Quality (5)
- Security & Infrastructure (3)
- Platform Development (6)
- Infrastructure & Data (5)
- Advanced Specializations (12)

**Intelligent Agent Auto-Activation**:
- **Legal docs** → `spec-legal-counsel`
- **UI/UX** → `spec-ux-user-experience` + `spec-ux-guardian`
- **Security** → `spec-security-sentinel`
- **Performance** → `spec-performance-guru` + `spec-ai-model-optimizer`
- **Market analysis** → `spec-analyst` + `spec-market-analyst`
- **Requirements** → `spec-requirements`
- **Quality validation** → `spec-judge` orchestrating relevant specialists
- **Privacy & security** → `spec-data-privacy-security-analyst` + `spec-security-sentinel`
- **AI performance** → `spec-ai-performance-optimizer` + `spec-performance-guru`
- **AI-powered design** → `spec-ai-powered-ux-designer` + `spec-ux-user-experience`

## Project Overview

HMI2.ai ("Human Machine Interface, Reimagined") is developing Roadtrip-Copilot: "The Expedia of Roadside Discoveries" - a real-time voice AI companion for iOS and Android, with Apple CarPlay and Android Auto integration. It uses on-device LLMs to minimize latency and server costs, creating a user-powered economy where travelers can earn free roadtrips.

## Technology Stack

- **iOS**: Swift 5.9+, SwiftUI, CarPlay, Core ML, Apple Neural Engine.
- **Android**: Kotlin 1.9+, Jetpack Compose, Android Auto, MediaPipe/TFLite, NNAPI.
- **AI**: Gemma-3B/Phi-3-mini LLM, Kitten TTS, Kokoro TTS.
- **Backend**: Cloudflare Workers & Supabase.

## Development Commands

- **iOS**: `cd ios && xcodebuild build`, `cd ios && open Roadtrip-Copilot.xcodeproj`, `cd ios && xcodebuild test`
- **Android**: `cd android && ./gradlew assembleDebug`, `cd android && ./gradlew installDebug`, `cd android && ./gradlew test`
- **Models**: `python models/conversion/convert_*.py`, `python models/quantization/quantize_models.py`
- **Backend**: `cd backend && wrangler dev`, `cd backend && supabase start`

## Architecture Highlights

- **On-Device AI**: 12 specialized agents run locally for <350ms response times.
- **Performance**: <525MB model size, <1.5GB RAM, <3% battery/hour.
- **User-Powered Economy**: 50/50 revenue sharing for new discoveries.