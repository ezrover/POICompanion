================================================
FILE: README.md
================================================
# Mobile Next - MCP server for Mobile Development and Automation  | iOS, Android, Simulator, Emulator, and physical devices

This is a [Model Context Protocol (MCP) server](https://github.com/modelcontextprotocol) that enables scalable mobile automation, development through a platform-agnostic interface, eliminating the need for distinct iOS or Android knowledge. You can run it on emulators, simulators, and physical devices (iOS and Android).
This server allows Agents and LLMs to interact with native iOS/Android applications and devices through structured accessibility snapshots or coordinate-based taps based on screenshots.

<h4 align="center">
<a href="https://github.com/mobile-next/mobile-mcp">
    <img src="https://img.shields.io/github/stars/mobile-next/mobile-mcp" alt="Mobile Next Stars" />
  </a>
 <a href="https://github.com/mobile-next/mobile-mcp">
    <img src="https://img.shields.io/github/contributors/mobile-next/mobile-mcp?color=green" alt="Mobile Next Downloads" />
  </a>
  <a href="https://www.npmjs.com/package/@mobilenext/mobile-mcp">
    <img src="https://img.shields.io/npm/dm/@mobilenext/mobile-mcp?logo=npm&style=flat&color=red" alt="npm">
  </a>
<a href="https://github.com/mobile-next/mobile-mcp/releases">
    <img src="https://img.shields.io/github/release/mobile-next/mobile-mcp">
  </a>
<a href="https://github.com/mobile-next/mobile-mcp/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-Apache 2.0-blue.svg" alt="Mobile MCP is released under the Apache-2.0 License">
  </a>

</p>

<h4 align="center">
<a href="http://mobilenexthq.com/join-slack">
    <img src="https://img.shields.io/badge/join-Slack-blueviolet?logo=slack&style=flat" alt="Slack community channel" />
</a>
</p>

https://github.com/user-attachments/assets/c4e89c4f-cc71-4424-8184-bdbc8c638fa1

<p align="center">
    <a href="https://github.com/mobile-next/">
        <img alt="mobile-mcp" src="https://raw.githubusercontent.com/mobile-next/mobile-next-assets/refs/heads/main/mobile-mcp-banner.png" width="600">
    </a>
</p>

### 🚀 Mobile MCP Roadmap: Building the Future of Mobile

Join us on our journey as we continuously enhance Mobile MCP!
Check out our detailed roadmap to see upcoming features, improvements, and milestones. Your feedback is invaluable in shaping the future of mobile automation.

👉 [Explore the Roadmap](https://github.com/orgs/mobile-next/projects/3)


### Main use cases

How we help to scale mobile automation:

- 📲 Native app automation (iOS and Android) for testing or data-entry scenarios.
- 📝 Scripted flows and form interactions without manually controlling simulators/emulators or physical devices (iPhone, Samsung, Google Pixel etc)
- 🧭 Automating multi-step user journeys driven by an LLM
- 👆 General-purpose mobile application interaction for agent-based frameworks
- 🤖 Enables agent-to-agent communication for mobile automation usecases, data extraction

## Main Features

- 🚀 **Fast and lightweight**: Uses native accessibility trees for most interactions, or screenshot based coordinates where a11y labels are not available.
- 🤖 **LLM-friendly**: No computer vision model required in Accessibility (Snapshot).
- 🧿 **Visual Sense**: Evaluates and analyses what’s actually rendered on screen to decide the next action. If accessibility data or view-hierarchy coordinates are unavailable, it falls back to screenshot-based analysis.
- 📊 **Deterministic tool application**: Reduces ambiguity found in purely screenshot-based approaches by relying on structured data whenever possible.
- 📺 **Extract structured data**: Enables you to extract structred data from anything visible on screen.

## 🏗️ Mobile MCP Architecture

<p align="center">
    <a href="https://raw.githubusercontent.com/mobile-next/mobile-next-assets/refs/heads/main/mobile-mcp-arch-1.png">
        <img alt="mobile-mcp" src="https://raw.githubusercontent.com/mobile-next/mobile-next-assets/refs/heads/main/mobile-mcp-arch-1.png" width="600">
    </a>
</p>


## 📚 Wiki page

More details in our [wiki page](https://github.com/mobile-next/mobile-mcp/wiki) for setup, configuration and debugging related questions.


## Installation and configuration

Setup our MCP with Cline, Cursor, Claude, VS Code, Github Copilot:

```json
{
  "mcpServers": {
    "mobile-mcp": {
      "command": "npx",
      "args": ["-y", "@mobilenext/mobile-mcp@latest"]
    }
  }
}

```
[Cline:](https://docs.cline.bot/mcp/configuring-mcp-servers) To setup Cline, just add the json above to your MCP settings file.
[More in our wiki](https://github.com/mobile-next/mobile-mcp/wiki/Cline)

[Claude Code:](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview)

```
claude mcp add mobile -- npx -y @mobilenext/mobile-mcp@latest
```

[Read more in our wiki](https://github.com/mobile-next/mobile-mcp/wiki)! 🚀


### 🛠️ How to Use 📝

After adding the MCP server to your IDE/Client, you can instruct your AI assistant to use the available tools.
For example, in Cursor's agent mode, you could use the prompts below to quickly validate, test and iterate on UI intereactions, read information from screen, go through complex workflows.
Be descriptive, straight to the point.

### ✨ Example Prompts

#### Workflows

You can specifiy detailed workflows in a single prompt, verify business logic, setup automations. You can go crazy:

**Search for a video, comment, like and share it.**
```
Find the video called " Beginner Recipe for Tonkotsu Ramen" by Way of
Ramen, click on like video, after liking write a comment " this was
delicious, will make it next Friday", share the video with the first
contact in your whatsapp list.
```

**Download a successful step counter app, register, setup workout and 5-star the app**
```
Find and Download a free "Pomodoro" app that has more than 1k stars.
Launch the app, register with my email, after registration find how to
start a pomodoro timer. When the pomodoro timer started, go back to the
app store and rate the app 5 stars, and leave a comment how useful the
app is.
```

**Search in Substack, read, highlight, comment and save an article**
```
Open Substack website, search for "Latest trends in AI automation 2025",
open the first article, highlight the section titled "Emerging AI trends",
and save article to reading list for later review, comment a random
paragraph summary.
```

**Reserve a workout class, set timer**
```
Open ClassPass, search for yoga classes tomorrow morning within 2 miles,
book the highest-rated class at 7 AM, confirm reservation,
setup a timer for the booked slot in the phone
```

**Find a local event, setup calendar event**
```
Open Eventbrite, search for AI startup meetup events happening this
weekend in "Austin, TX", select the most popular one, register and RSVP
yes to the event, setup a calendar event as a reminder.
```

**Check weather forecast and send a Whatsapp/Telegram/Slack message**
```
Open Weather app, check tomorrow's weather forecast for "Berlin", and
send the summary via Whatsapp/Telegram/Slack to contact "Lauren Trown",
thumbs up their response.
```

- **Schedule a meeting in Zoom and share invite via email**
```
Open Zoom app, schedule a meeting titled "AI Hackathon" for tomorrow at
10AM with a duration of 1 hour, copy the invitation link, and send it via
Gmail to contacts "team@example.com".
```
[More prompt examples can be found here.](https://github.com/mobile-next/mobile-mcp/wiki/Prompt-Example-repo-list)

## Prerequisites

What you will need to connect MCP with your agent and mobile devices:

- [Xcode command line tools](https://developer.apple.com/xcode/resources/)
- [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools)
- [node.js](https://nodejs.org/en/download/) v22+
- [MCP](https://modelcontextprotocol.io/introduction) supported foundational models or agents, like [Claude MCP](https://modelcontextprotocol.io/quickstart/server), [OpenAI Agent SDK](https://openai.github.io/openai-agents-python/mcp/), [Copilot Studio](https://www.microsoft.com/en-us/microsoft-copilot/blog/copilot-studio/introducing-model-context-protocol-mcp-in-copilot-studio-simplified-integration-with-ai-apps-and-agents/)

### Simulators, Emulators, and Physical Devices

When launched, Mobile MCP can connect to:
- iOS Simulators on macOS/Linux
- Android Emulators on Linux/Windows/macOS
- Physical iOS or Android devices (requires proper platform tools and drivers)

Make sure you have your mobile platform SDKs (Xcode, Android SDK) installed and configured properly before running Mobile Next Mobile MCP.

### Running in "headless" mode on Simulators/Emulators

When you do not have a physical phone connected to your machine, you can run Mobile MCP with an emulator or simulator in the background.

For example, on Android:
1. Start an emulator (avdmanager / emulator command).
2. Run Mobile MCP with the desired flags

On iOS, you'll need Xcode and to run the Simulator before using Mobile MCP with that simulator instance.
- `xcrun simctl list`
- `xcrun simctl boot "iPhone 16"`

# Thanks to all contributors ❤️

### We appreciate everyone who has helped improve this project.

  <a href = "https://github.com/mobile-next/mobile-mcp/graphs/contributors">
   <img src = "https://contrib.rocks/image?repo=mobile-next/mobile-mcp"/>
 </a>




================================================
FILE: CHANGELOG.md
================================================
## [0.0.23](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.23) (2025-07-31)

* Andrid: fixed a bug where devices with multiple screens (such as foldables) failed to take and save screenshot ([#159](https://github.com/mobile-next/mobile-mcp/pull/159))

## [0.0.22](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.22) (2025-07-17)

* iOS: fixed detection of go-ios installation ([#132](https://github.com/mobile-next/mobile-mcp/pull/132) by [@codeaholicguy](https://github.com/codeaholicguy)

## [0.0.21](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.21) (2025-06-27)

* Server: use node: prefixed modules (like node:fs) ([449c498](https://github.com/mobile-next/mobile-mcp/commit/449c498e6e9a3e68aab55ea82f15c296171fc05e))
* iOS: automatically start WebDriverAgent on simulator if already installed ([#126](https://github.com/mobile-next/mobile-mcp/pull/126))
* Android: fixed detection of com.mobilenext.devicekit when running mcp on windows ([c11c642](https://github.com/mobile-next/mobile-mcp/commit/c11c6427c71cb7cef6ce87005047df977f6bea8a))

## [0.0.20](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.20) (2025-06-23)

* Server: new tool `save_screenshot` which saves the screenshot to disk, to be used by other mcp servers ([#112](https://github.com/mobile-next/mobile-mcp/pull/112))
* Server: new tool `use_default_device` which picks the only device that is connected, to speed up use ([#112](https://github.com/mobile-next/mobile-mcp/pull/112))
* iOS: Use wda to grab screenshots for both real devices and simulators ([#115](https://github.com/mobile-next/mobile-mcp/pull/115))
* Android: Support for utf-8 text in sendKeys, see [wiki page]() for getting started ([#117](https://github.com/mobile-next/mobile-mcp/pull/117))

## [0.0.19](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.19) (2025-06-16)

* Server: Fixed support for Windsurf, where some tools caused a -32602 error ([#101](https://github.com/mobile-next/mobile-mcp/pull/101)) by [@amebahead](https://github.com/amebahead)
* iOS: Support for swipe left and right. Support x,y,direction,duration for custom swipes ([#92](https://github.com/mobile-next/mobile-mcp/pull/92/)) by [@benlmyers](https://github.com/benlmyers)
* Android: Support for swipe left and right. Support x,y,direction,duration for custom swipes ([#92](https://github.com/mobile-next/mobile-mcp/pull/92/)) by [@benlmyers](https://github.com/benlmyers)
* Android: Fix for get elements on screen, where uiautomator prints out warnings before the actual xml ([#86](https://github.com/mobile-next/mobile-mcp/pull/86)) by [@wenerme](https://github.com/wenerme)

## [0.0.18](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.18) (2025-06-12)

* Server: New support for SSE (Server-Sent-Events) transport, [see wiki for more information](https://github.com/mobile-next/mobile-mcp/wiki/Using-SSE-Transport) ([1b70d40](https://github.com/mobile-next/mobile-mcp/commit/1b70d403cd562a97a0723464f2b286f2fd6eee0a))
* iOS: Using plutil for `simctl listapps` parsing, might probably fix some parsing issues ([cfba3aa](https://github.com/mobile-next/mobile-mcp/commit/cfba3aaac5beb66d08d1138fe42c924309ede303))
* Other: We have a new Slack server, join us at http://mobilenexthq.com/join-slack

## [0.0.17](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.17) (2025-05-16)

* iOS: Fixed parsing of simctl listapps where CFBundleDisplayName contains non-alphanumerical characters ([#59](https://github.com/mobile-next/mobile-mcp/issues/59)) ([bf19771d](https://github.com/mobile-next/mobile-mcp/pull/63/commits/bf19771dcd49444ba4841ec649e3a72a03b54c74))

## [0.0.16](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.16) (2025-05-10)

* Server: Detect if there is a new version of the mcp and notify user ([14b015f](https://github.com/mobile-next/mobile-mcp/commit/14b015f29ab47aa1f3ae122a670a58eb7ef51fd8))
* Server: Instead of returning x,y for tap, return [top,left,width,height] of elements on screen ([3169d2f](https://github.com/mobile-next/mobile-mcp/commit/3169d2f46f0c789e4c3188e137ac645d6f6eb27c))
* iOS: Fixed coordinates location for iOS with retina display after image scaledown ([3169d2f](https://github.com/mobile-next/mobile-mcp/commit/3169d2f46f0c789e4c3188e137ac645d6f6eb27c))
* iOS: Added detection of StaticText and Image in mobile_list_elements_on_screen ([debe75b](https://github.com/mobile-next/mobile-mcp/commit/debe75b5c8afcafcef8328201e9886bffdd1f128))

## [0.0.15](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.15) (2025-05-04)

* Android: Fixed broken Android screenshots on Windows because of crlf ([#53](https://github.com/mobile-next/mobile-mcp/pull/53/files) by [@hanyuan97](https://github.com/hanyuan97))

## [0.0.14](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.14) (2025-05-02)

* Server: Fix a bug where xcrun was required, now works on Linux as well ([7fddba7](https://github.com/mobile-next/mobile-mcp/commit/7fddba71af51690cfa76f81154f72c3120ab7f07))
* Server: Removed dependency on sharp which was causing issues during installation, now ImageMagick is an optional dependency
* Android: Try uiautomator-dump multiple times, in case ui hierarchy is not stable
* Android: Return more information about elements on screen for better element detection
* Android: Support for Android TV using dpad for navigation ([399443d](https://github.com/mobile-next/mobile-mcp/commit/399443d519284a54b670a1598689a73d178db2ec) by [@surajsau](https://github.com/surajsau))

## [0.0.13](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.13) (2025-04-17)

* Server: Fix a bug where 'adb' is required to even work with iOS-only ([#30](https://github.com/mobile-next/mobile-mcp/issues/30)) ([867f662](https://github.com/mobile-next/mobile-mcp/pull/35/commits/867f662ac2edc68d542519bd72d1762d3dbca18d))
* iOS: Support for orientation changes ([844dc0e](https://github.com/mobile-next/mobile-mcp/pull/28/commits/844dc0eb953169871b4cdd2a57735bf50abe721a))
* Android: Support for orientation changes (eg 'change device to landscape') ([844dc0e](https://github.com/mobile-next/mobile-mcp/pull/28/commits/844dc0eb953169871b4cdd2a57735bf50abe721a))
* Android: Improve element detection by using element name if label not found ([8e8aadf](https://github.com/mobile-next/mobile-mcp/pull/33/commits/8e8aadfd7f300ff5b7f0a7857a99d1103cd9e941) by [@tomoya0x00](https://github.com/tomoya0x00))

## [0.0.12](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.12) (2025-04-12)

* Server: If hitting an error with tunnel, forward proxy, wda, descriptive error and link to documentation will be returned
* iOS: go-ios path can be set in env GO_IOS_PATH
* iOS: Support go-ios that was built locally (no version)
* iOS: Return bundle display name for apps for better app launch
* iOS: Fixed finding element coordinates on retina displays
* iOS: Saving temporary screenshots onto temporary directory ([#19](https://github.com/mobile-next/mobile-mcp/issues/19))
* iOS: Find elements better by removing off-screen and hidden elements
* Android: Support for 'adb' under ANDROID_HOME
* Android: Find elements better using accessibility hints and class names

## [0.0.11](https://github.com/mobile-next/mobile-mcp/releases/tag/0.0.11) (2025-04-06)

* Server: Support submit after sending text (\n)
* Server: Added support for multiple devices at the same time
* iOS: Support for iOS physical devices using go-ios ([see wiki](https://github.com/mobile-next/mobile-mcp/wiki/Getting-Started-with-iOS-Physical-Device))
* iOS: Added support for icons, search fields, and switches when getting elements on screen



================================================
FILE: eslint.config.mjs
================================================
import typescriptEslint from "@typescript-eslint/eslint-plugin";
import tsParser from "@typescript-eslint/parser";
import stylistic from "@stylistic/eslint-plugin";
import importRules from "eslint-plugin-import";

const plugins = {
	"@stylistic": stylistic,
	"@typescript-eslint": typescriptEslint,
	import: importRules,
};

export const baseRules = {
	"@typescript-eslint/no-unused-vars": [
		2,
		{args: "none", caughtErrors: "none"},
	],

	/**
	 * Enforced rules
	 */
	// syntax preferences
	"object-curly-spacing": ["error", "always"],
	quotes: [
		2,
		"double",
		{
			avoidEscape: true,
			allowTemplateLiterals: true,
		},
	],
	"jsx-quotes": [2, "prefer-single"],
	"no-extra-semi": 2,
	"@stylistic/semi": [2],
	"comma-style": [2, "last"],
	"wrap-iife": [2, "inside"],
	"spaced-comment": [
		2,
		"always",
		{
			markers: ["*"],
		},
	],
	eqeqeq: [2],
	"accessor-pairs": [
		2,
		{
			getWithoutSet: false,
			setWithoutGet: false,
		},
	],
	"brace-style": [2, "1tbs", {allowSingleLine: true}],
	curly: [2, "all"],
	"new-parens": 2,
	"arrow-parens": [2, "as-needed"],
	"prefer-const": 2,
	"quote-props": [2, "consistent"],
	"nonblock-statement-body-position": [2, "below"],

	// anti-patterns
	"no-var": 2,
	"no-with": 2,
	"no-multi-str": 2,
	"no-caller": 2,
	"no-implied-eval": 2,
	"no-labels": 2,
	"no-new-object": 2,
	"no-octal-escape": 2,
	"no-self-compare": 2,
	"no-shadow-restricted-names": 2,
	"no-cond-assign": 2,
	"no-debugger": 2,
	"no-dupe-keys": 2,
	"no-duplicate-case": 2,
	"no-empty-character-class": 2,
	"no-unreachable": 2,
	"no-unsafe-negation": 2,
	radix: 2,
	"valid-typeof": 2,
	"no-implicit-globals": [2],
	"no-unused-expressions": [
		2,
		{allowShortCircuit: true, allowTernary: true, allowTaggedTemplates: true},
	],
	"no-proto": 2,

	// es2015 features
	"require-yield": 2,
	"template-curly-spacing": [2, "never"],

	// spacing details
	"space-infix-ops": 2,
	"space-in-parens": [2, "never"],
	"array-bracket-spacing": [2, "never"],
	"comma-spacing": [2, {before: false, after: true}],
	"keyword-spacing": [2, "always"],
	"space-before-function-paren": [
		2,
		{
			anonymous: "never",
			named: "never",
			asyncArrow: "always",
		},
	],
	"no-whitespace-before-property": 2,
	"keyword-spacing": [
		2,
		{
			overrides: {
				if: {after: true},
				else: {after: true},
				for: {after: true},
				while: {after: true},
				do: {after: true},
				switch: {after: true},
				return: {after: true},
			},
		},
	],
	"arrow-spacing": [
		2,
		{
			after: true,
			before: true,
		},
	],
	"@stylistic/func-call-spacing": 2,
	"@stylistic/type-annotation-spacing": 2,

	// file whitespace
	"no-multiple-empty-lines": [2, {max: 2, maxEOF: 0}],
	"no-mixed-spaces-and-tabs": 2,
	"no-trailing-spaces": 2,
	"linebreak-style": [process.platform === "win32" ? 0 : 2, "unix"],
	indent: [
		2,
		"tab",
		{SwitchCase: 1, CallExpression: {arguments: "first"}, MemberExpression: 1},
	],
	"key-spacing": [
		2,
		{
			beforeColon: false,
		},
	],
	"eol-last": 2,
};

const languageOptions = {
	parser: tsParser,
	ecmaVersion: 9,
	sourceType: "module",
};

export default [
	{
		files: ["**/*.ts"],
		plugins,
		languageOptions,
		rules: baseRules,
	},
];



================================================
FILE: LICENSE
================================================
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.



================================================
FILE: package.json
================================================
{
  "name": "@mobilenext/mobile-mcp",
  "version": "0.0.1",
  "description": "Mobile MCP",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/mobile-next/mobile-mcp.git"
  },
  "engines": {
    "node": ">=18"
  },
  "license": "Apache-2.0",
  "scripts": {
    "build": "tsc && chmod +x lib/index.js",
    "lint": "eslint .",
    "test": "nyc mocha --require ts-node/register test/*.ts",
    "watch": "tsc --watch",
    "clean": "rm -rf lib",
    "prepare": "husky"
  },
  "files": [
    "lib"
  ],
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.6.1",
    "commander": "^14.0.0",
    "express": "^5.1.0",
    "fast-xml-parser": "^5.0.9",
    "zod-to-json-schema": "^3.24.4"
  },
  "devDependencies": {
    "@eslint/eslintrc": "^3.2.0",
    "@eslint/js": "^9.19.0",
    "@stylistic/eslint-plugin": "^3.0.1",
    "@types/commander": "^2.12.0",
    "@types/express": "^5.0.3",
    "@types/mocha": "^10.0.10",
    "@types/node": "^22.13.10",
    "@typescript-eslint/eslint-plugin": "^8.28.0",
    "@typescript-eslint/parser": "^8.26.1",
    "@typescript-eslint/utils": "^8.26.1",
    "eslint": "^9.19.0",
    "eslint-plugin": "^1.0.1",
    "eslint-plugin-import": "^2.31.0",
    "eslint-plugin-notice": "^1.0.0",
    "husky": "^9.1.7",
    "mocha": "^11.1.0",
    "nyc": "^17.1.0",
    "ts-node": "^10.9.2",
    "typescript": "^5.8.2"
  },
  "main": "index.js",
  "bin": {
    "mcp-server-mobile": "lib/index.js"
  },
  "directories": {
    "lib": "lib"
  },
  "author": "",
  "bugs": {
    "url": "https://github.com/mobile-next/mobile-mcp/issues"
  },
  "homepage": "https://github.com/mobile-next/mobile-mcp#readme"
}



================================================
FILE: tsconfig.json
================================================
{
  "compilerOptions": {
    "target": "ESNext",
    "skipLibCheck": true,
    "esModuleInterop": true,
    "moduleResolution": "node",
    "strict": true,
    "module": "CommonJS",
    "outDir": "./lib"
  },
  "include": [
    "src",
  ],
}


================================================
FILE: .editorconfig
================================================
[*]
indent_style = tab
indent_size = 8
tab_width = 8
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
max_line_length = 150



================================================
FILE: .mocharc.yml
================================================
timeout: 60s



================================================
FILE: .npmignore
================================================
**/*
README.md
LICENSE
!index.*
!lib/**/*.js



================================================
FILE: src/android.ts
================================================
import path from "node:path";
import { execFileSync } from "node:child_process";

import * as xml from "fast-xml-parser";

import { ActionableError, Button, InstalledApp, Robot, ScreenElement, ScreenElementRect, ScreenSize, SwipeDirection, Orientation } from "./robot";

export interface AndroidDevice {
	deviceId: string;
	deviceType: "tv" | "mobile";
}

interface UiAutomatorXmlNode {
	node: UiAutomatorXmlNode[];
	class?: string;
	text?: string;
	bounds?: string;
	hint?: string;
	focused?: string;
	"content-desc"?: string;
	"resource-id"?: string;
}

interface UiAutomatorXml {
	hierarchy: {
		node: UiAutomatorXmlNode;
	};
}

const getAdbPath = (): string => {
	let executable = "adb";
	if (process.env.ANDROID_HOME) {
		executable = path.join(process.env.ANDROID_HOME, "platform-tools", "adb");
	}

	return executable;
};

const BUTTON_MAP: Record<Button, string> = {
	"BACK": "KEYCODE_BACK",
	"HOME": "KEYCODE_HOME",
	"VOLUME_UP": "KEYCODE_VOLUME_UP",
	"VOLUME_DOWN": "KEYCODE_VOLUME_DOWN",
	"ENTER": "KEYCODE_ENTER",
	"DPAD_CENTER": "KEYCODE_DPAD_CENTER",
	"DPAD_UP": "KEYCODE_DPAD_UP",
	"DPAD_DOWN": "KEYCODE_DPAD_DOWN",
	"DPAD_LEFT": "KEYCODE_DPAD_LEFT",
	"DPAD_RIGHT": "KEYCODE_DPAD_RIGHT",
};

const TIMEOUT = 30000;
const MAX_BUFFER_SIZE = 1024 * 1024 * 4;

type AndroidDeviceType = "tv" | "mobile";

export class AndroidRobot implements Robot {

	public constructor(private deviceId: string) {
	}

	public adb(...args: string[]): Buffer {
		return execFileSync(getAdbPath(), ["-s", this.deviceId, ...args], {
			maxBuffer: MAX_BUFFER_SIZE,
			timeout: TIMEOUT,
		});
	}

	public getFirstDisplayId(): string | null {
		const output = this.adb("shell", "dumpsys", "SurfaceFlinger", "--display-id").toString();
		const match = output.match(/Display (\d+) \(/);
		return match ? match[1] : null;
	}

	public getSystemFeatures(): string[] {
		return this.adb("shell", "pm", "list", "features")
			.toString()
			.split("\n")
			.map(line => line.trim())
			.filter(line => line.startsWith("feature:"))
			.map(line => line.substring("feature:".length));
	}

	public async getScreenSize(): Promise<ScreenSize> {
		const screenSize = this.adb("shell", "wm", "size")
			.toString()
			.split(" ")
			.pop();

		if (!screenSize) {
			throw new Error("Failed to get screen size");
		}

		const scale = 1;
		const [width, height] = screenSize.split("x").map(Number);
		return { width, height, scale };
	}

	public async listApps(): Promise<InstalledApp[]> {
		// only apps that have a launcher activity are returned
		return this.adb("shell", "cmd", "package", "query-activities", "-a", "android.intent.action.MAIN", "-c", "android.intent.category.LAUNCHER")
			.toString()
			.split("\n")
			.map(line => line.trim())
			.filter(line => line.startsWith("packageName="))
			.map(line => line.substring("packageName=".length))
			.filter((value, index, self) => self.indexOf(value) === index)
			.map(packageName => ({
				packageName,
				appName: packageName,
			}));
	}

	private async listPackages(): Promise<string[]> {
		return this.adb("shell", "pm", "list", "packages")
			.toString()
			.split("\n")
			.map(line => line.trim())
			.filter(line => line.startsWith("package:"))
			.map(line => line.substring("package:".length));
	}

	public async launchApp(packageName: string): Promise<void> {
		this.adb("shell", "monkey", "-p", packageName, "-c", "android.intent.category.LAUNCHER", "1");
	}

	public async listRunningProcesses(): Promise<string[]> {
		return this.adb("shell", "ps", "-e")
			.toString()
			.split("\n")
			.map(line => line.trim())
			.filter(line => line.startsWith("u")) // non-system processes
			.map(line => line.split(/\s+/)[8]); // get process name
	}

	public async swipe(direction: SwipeDirection): Promise<void> {
		const screenSize = await this.getScreenSize();
		const centerX = screenSize.width >> 1;

		let x0: number, y0: number, x1: number, y1: number;

		switch (direction) {
			case "up":
				x0 = x1 = centerX;
				y0 = Math.floor(screenSize.height * 0.80);
				y1 = Math.floor(screenSize.height * 0.20);
				break;
			case "down":
				x0 = x1 = centerX;
				y0 = Math.floor(screenSize.height * 0.20);
				y1 = Math.floor(screenSize.height * 0.80);
				break;
			case "left":
				x0 = Math.floor(screenSize.width * 0.80);
				x1 = Math.floor(screenSize.width * 0.20);
				y0 = y1 = Math.floor(screenSize.height * 0.50);
				break;
			case "right":
				x0 = Math.floor(screenSize.width * 0.20);
				x1 = Math.floor(screenSize.width * 0.80);
				y0 = y1 = Math.floor(screenSize.height * 0.50);
				break;
			default:
				throw new ActionableError(`Swipe direction "${direction}" is not supported`);
		}

		this.adb("shell", "input", "swipe", `${x0}`, `${y0}`, `${x1}`, `${y1}`, "1000");
	}

	public async swipeFromCoordinate(x: number, y: number, direction: SwipeDirection, distance?: number): Promise<void> {
		const screenSize = await this.getScreenSize();

		let x0: number, y0: number, x1: number, y1: number;

		// Use provided distance or default to 30% of screen dimension
		const defaultDistanceY = Math.floor(screenSize.height * 0.3);
		const defaultDistanceX = Math.floor(screenSize.width * 0.3);
		const swipeDistanceY = distance || defaultDistanceY;
		const swipeDistanceX = distance || defaultDistanceX;

		switch (direction) {
			case "up":
				x0 = x1 = x;
				y0 = y;
				y1 = Math.max(0, y - swipeDistanceY);
				break;
			case "down":
				x0 = x1 = x;
				y0 = y;
				y1 = Math.min(screenSize.height, y + swipeDistanceY);
				break;
			case "left":
				x0 = x;
				x1 = Math.max(0, x - swipeDistanceX);
				y0 = y1 = y;
				break;
			case "right":
				x0 = x;
				x1 = Math.min(screenSize.width, x + swipeDistanceX);
				y0 = y1 = y;
				break;
			default:
				throw new ActionableError(`Swipe direction "${direction}" is not supported`);
		}

		this.adb("shell", "input", "swipe", `${x0}`, `${y0}`, `${x1}`, `${y1}`, "1000");
	}

	public async getScreenshot(): Promise<Buffer> {
		const displayId = this.getFirstDisplayId();

		if (displayId !== null) {
			// always good to provide displayId. required for multi-display devices such as fold
			return this.adb("exec-out", "screencap", "-p", "-d", displayId);
		} else {
			// backward compatibility for android 10 and below
			return this.adb("exec-out", "screencap", "-p");
		}
	}

	private collectElements(node: UiAutomatorXmlNode): ScreenElement[] {
		const elements: Array<ScreenElement> = [];

		if (node.node) {
			if (Array.isArray(node.node)) {
				for (const childNode of node.node) {
					elements.push(...this.collectElements(childNode));
				}
			} else {
				elements.push(...this.collectElements(node.node));
			}
		}

		if (node.text || node["content-desc"] || node.hint) {
			const element: ScreenElement = {
				type: node.class || "text",
				text: node.text,
				label: node["content-desc"] || node.hint || "",
				rect: this.getScreenElementRect(node),
			};

			if (node.focused === "true") {
				// only provide it if it's true, otherwise don't confuse llm
				element.focused = true;
			}

			const resourceId = node["resource-id"];
			if (resourceId !== null && resourceId !== "") {
				element.identifier = resourceId;
			}

			if (element.rect.width > 0 && element.rect.height > 0) {
				elements.push(element);
			}
		}

		return elements;
	}

	public async getElementsOnScreen(): Promise<ScreenElement[]> {
		const parsedXml = await this.getUiAutomatorXml();
		const hierarchy = parsedXml.hierarchy;
		const elements = this.collectElements(hierarchy.node);
		return elements;
	}

	public async terminateApp(packageName: string): Promise<void> {
		this.adb("shell", "am", "force-stop", packageName);
	}

	public async openUrl(url: string): Promise<void> {
		this.adb("shell", "am", "start", "-a", "android.intent.action.VIEW", "-d", url);
	}

	private isAscii(text: string): boolean {
		return /^[\x00-\x7F]*$/.test(text);
	}

	private async isDeviceKitInstalled(): Promise<boolean> {
		const packages = await this.listPackages();
		return packages.includes("com.mobilenext.devicekit");
	}

	public async sendKeys(text: string): Promise<void> {
		if (text === "") {
			// bailing early, so we don't run adb shell with empty string.
			// this happens when you prompt with a simple "submit".
			return;
		}

		if (this.isAscii(text)) {
			// adb shell input only supports ascii characters. and
			// some of the keys have to be escaped.
			const _text = text.replace(/ /g, "\\ ");
			this.adb("shell", "input", "text", _text);
		} else if (await this.isDeviceKitInstalled()) {
			// try sending over clipboard
			const base64 = Buffer.from(text).toString("base64");

			// send clipboard over and immediately paste it
			this.adb("shell", "am", "broadcast", "-a", "devicekit.clipboard.set", "-e", "encoding", "base64", "-e", "text", base64, "-n", "com.mobilenext.devicekit/.ClipboardBroadcastReceiver");
			this.adb("shell", "input", "keyevent", "KEYCODE_PASTE");

			// clear clipboard when we're done
			this.adb("shell", "am", "broadcast", "-a", "devicekit.clipboard.clear", "-n", "com.mobilenext.devicekit/.ClipboardBroadcastReceiver");
		} else {
			throw new ActionableError("Non-ASCII text is not supported on Android, please install mobilenext devicekit, see https://github.com/mobile-next/devicekit-android");
		}
	}

	public async pressButton(button: Button) {
		if (!BUTTON_MAP[button]) {
			throw new ActionableError(`Button "${button}" is not supported`);
		}

		this.adb("shell", "input", "keyevent", BUTTON_MAP[button]);
	}

	public async tap(x: number, y: number): Promise<void> {
		this.adb("shell", "input", "tap", `${x}`, `${y}`);
	}

	public async setOrientation(orientation: Orientation): Promise<void> {
		const orientationValue = orientation === "portrait" ? 0 : 1;

		// disable auto-rotation prior to setting the orientation
		this.adb("shell", "settings", "put", "system", "accelerometer_rotation", "0");
		this.adb("shell", "content", "insert", "--uri", "content://settings/system", "--bind", "name:s:user_rotation", "--bind", `value:i:${orientationValue}`);
	}

	public async getOrientation(): Promise<Orientation> {
		const rotation = this.adb("shell", "settings", "get", "system", "user_rotation").toString().trim();
		return rotation === "0" ? "portrait" : "landscape";
	}

	private async getUiAutomatorDump(): Promise<string> {
		for (let tries = 0; tries < 10; tries++) {
			const dump = this.adb("exec-out", "uiautomator", "dump", "/dev/tty").toString();
			// note: we're not catching other errors here. maybe we should check for <?xml
			if (dump.includes("null root node returned by UiTestAutomationBridge")) {
				// uncomment for debugging
				// const screenshot = await this.getScreenshot();
				// console.error("Failed to get UIAutomator XML. Here's a screenshot: " + screenshot.toString("base64"));
				continue;
			}

			return dump.substring(dump.indexOf("<?xml"));
		}

		throw new ActionableError("Failed to get UIAutomator XML");
	}

	private async getUiAutomatorXml(): Promise<UiAutomatorXml> {
		const dump = await this.getUiAutomatorDump();
		const parser = new xml.XMLParser({
			ignoreAttributes: false,
			attributeNamePrefix: "",
		});

		return parser.parse(dump) as UiAutomatorXml;
	}

	private getScreenElementRect(node: UiAutomatorXmlNode): ScreenElementRect {
		const bounds = String(node.bounds);

		const [, left, top, right, bottom] = bounds.match(/^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$/)?.map(Number) || [];
		return {
			x: left,
			y: top,
			width: right - left,
			height: bottom - top,
		};
	}
}

export class AndroidDeviceManager {

	private getDeviceType(name: string): AndroidDeviceType {
		const device = new AndroidRobot(name);
		const features = device.getSystemFeatures();
		if (features.includes("android.software.leanback") || features.includes("android.hardware.type.television")) {
			return "tv";
		}

		return "mobile";
	}

	public getConnectedDevices(): AndroidDevice[] {
		try {
			const names = execFileSync(getAdbPath(), ["devices"])
				.toString()
				.split("\n")
				.map(line => line.trim())
				.filter(line => line !== "")
				.filter(line => !line.startsWith("List of devices attached"))
				.map(line => line.split("\t")[0]);

			return names.map(name => ({
				deviceId: name,
				deviceType: this.getDeviceType(name),
			}));
		} catch (error) {
			console.error("Could not execute adb command, maybe ANDROID_HOME is not set?");
			return [];
		}
	}
}



================================================
FILE: src/image-utils.ts
================================================
import { execFileSync, spawnSync } from "child_process";

const DEFAULT_JPEG_QUALITY = 75;

export class ImageTransformer {

	private newWidth: number = 0;
	private newFormat: "jpg" | "png" = "png";
	private jpegOptions: { quality: number } = { quality: DEFAULT_JPEG_QUALITY };

	constructor(private buffer: Buffer) {}

	public resize(width: number): ImageTransformer {
		this.newWidth = width;
		return this;
	}

	public jpeg(options: { quality: number }): ImageTransformer {
		this.newFormat = "jpg";
		this.jpegOptions = options;
		return this;
	}

	public png(): ImageTransformer {
		this.newFormat = "png";
		return this;
	}

	public toBuffer(): Buffer {
		const proc = spawnSync("magick", ["-", "-resize", `${this.newWidth}x`, "-quality", `${this.jpegOptions.quality}`, `${this.newFormat}:-`], {
			maxBuffer: 8 * 1024 * 1024,
			input: this.buffer
		});

		return proc.stdout;
	}
}

export class Image {
	constructor(private buffer: Buffer) {}

	public static fromBuffer(buffer: Buffer): Image {
		return new Image(buffer);
	}

	public resize(width: number): ImageTransformer {
		return new ImageTransformer(this.buffer).resize(width);
	}

	public jpeg(options: { quality: number }): ImageTransformer {
		return new ImageTransformer(this.buffer).jpeg(options);
	}
}

export const isImageMagickInstalled = (): boolean => {
	try {
		return execFileSync("magick", ["--version"])
			.toString()
			.split("\n")
			.filter(line => line.includes("Version: ImageMagick"))
			.length > 0;
	} catch (error) {
		return false;
	}
};



================================================
FILE: src/index.ts
================================================
#!/usr/bin/env node
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { createMcpServer, getAgentVersion } from "./server";
import { error } from "./logger";
import express from "express";
import { program } from "commander";

const startSseServer = async (port: number) => {
	const app = express();
	const server = createMcpServer();

	let transport: SSEServerTransport | null = null;

	app.post("/mcp", (req, res) => {
		if (transport) {
			transport.handlePostMessage(req, res);
		}
	});

	app.get("/mcp", (req, res) => {
		if (transport) {
			transport.close();
		}

		transport = new SSEServerTransport("/mcp", res);
		server.connect(transport);
	});

	app.listen(port, () => {
		error(`mobile-mcp ${getAgentVersion()} sse server listening on http://localhost:${port}/mcp`);
	});
};

const startStdioServer = async () => {
	try {
		const transport = new StdioServerTransport();

		const server = createMcpServer();
		await server.connect(transport);

		error("mobile-mcp server running on stdio");
	} catch (err: any) {
		console.error("Fatal error in main():", err);
		error("Fatal error in main(): " + JSON.stringify(err.stack));
		process.exit(1);
	}
};

const main = async () => {
	program
		.version(getAgentVersion())
		.option("--port <port>", "Start SSE server on this port")
		.option("--stdio", "Start stdio server (default)")
		.parse(process.argv);

	const options = program.opts();

	if (options.port) {
		await startSseServer(+options.port);
	} else {
		await startStdioServer();
	}
};

main().then();



================================================
FILE: src/ios.ts
================================================
import { Socket } from "node:net";
import { execFileSync } from "node:child_process";

import { WebDriverAgent } from "./webdriver-agent";
import { ActionableError, Button, InstalledApp, Robot, ScreenSize, SwipeDirection, ScreenElement, Orientation } from "./robot";

const WDA_PORT = 8100;
const IOS_TUNNEL_PORT = 60105;

interface ListCommandOutput {
	deviceList: string[];
}

interface VersionCommandOutput {
	version: string;
}

interface InfoCommandOutput {
	DeviceClass: string;
	DeviceName: string;
	ProductName: string;
	ProductType: string;
	ProductVersion: string;
	PhoneNumber: string;
	TimeZone: string;
}

export interface IosDevice {
	deviceId: string;
	deviceName: string;
}

const getGoIosPath = (): string => {
	if (process.env.GO_IOS_PATH) {
		return process.env.GO_IOS_PATH;
	}

	// fallback to go-ios in PATH via `npm install -g go-ios`
	return "ios";
};

export class IosRobot implements Robot {

	public constructor(private deviceId: string) {
	}

	private isListeningOnPort(port: number): Promise<boolean> {
		return new Promise((resolve, reject) => {
			const client = new Socket();
			client.connect(port, "localhost", () => {
				client.destroy();
				resolve(true);
			});

			client.on("error", (err: any) => {
				resolve(false);
			});
		});
	}

	private async isTunnelRunning(): Promise<boolean> {
		return await this.isListeningOnPort(IOS_TUNNEL_PORT);
	}

	private async isWdaForwardRunning(): Promise<boolean> {
		return await this.isListeningOnPort(WDA_PORT);
	}

	private async assertTunnelRunning(): Promise<void> {
		if (await this.isTunnelRequired()) {
			if (!(await this.isTunnelRunning())) {
				throw new ActionableError("iOS tunnel is not running, please see https://github.com/mobile-next/mobile-mcp/wiki/");
			}
		}
	}

	private async wda(): Promise<WebDriverAgent> {

		await this.assertTunnelRunning();

		if (!(await this.isWdaForwardRunning())) {
			throw new ActionableError("Port forwarding to WebDriverAgent is not running (tunnel okay), please see https://github.com/mobile-next/mobile-mcp/wiki/");
		}

		const wda = new WebDriverAgent("localhost", WDA_PORT);

		if (!(await wda.isRunning())) {
			throw new ActionableError("WebDriverAgent is not running on device (tunnel okay, port forwarding okay), please see https://github.com/mobile-next/mobile-mcp/wiki/");
		}

		return wda;
	}

	private async ios(...args: string[]): Promise<string> {
		return execFileSync(getGoIosPath(), ["--udid", this.deviceId, ...args], {}).toString();
	}

	public async getIosVersion(): Promise<string> {
		const output = await this.ios("info");
		const json = JSON.parse(output);
		return json.ProductVersion;
	}

	private async isTunnelRequired(): Promise<boolean> {
		const version = await this.getIosVersion();
		const args = version.split(".");
		return parseInt(args[0], 10) >= 17;
	}

	public async getScreenSize(): Promise<ScreenSize> {
		const wda = await this.wda();
		return await wda.getScreenSize();
	}

	public async swipe(direction: SwipeDirection): Promise<void> {
		const wda = await this.wda();
		await wda.swipe(direction);
	}

	public async swipeFromCoordinate(x: number, y: number, direction: SwipeDirection, distance?: number): Promise<void> {
		const wda = await this.wda();
		await wda.swipeFromCoordinate(x, y, direction, distance);
	}

	public async listApps(): Promise<InstalledApp[]> {
		await this.assertTunnelRunning();

		const output = await this.ios("apps", "--all", "--list");
		return output
			.split("\n")
			.map(line => {
				const [packageName, appName] = line.split(" ");
				return {
					packageName,
					appName,
				};
			});
	}

	public async launchApp(packageName: string): Promise<void> {
		await this.assertTunnelRunning();
		await this.ios("launch", packageName);
	}

	public async terminateApp(packageName: string): Promise<void> {
		await this.assertTunnelRunning();
		await this.ios("kill", packageName);
	}

	public async openUrl(url: string): Promise<void> {
		const wda = await this.wda();
		await wda.openUrl(url);
	}

	public async sendKeys(text: string): Promise<void> {
		const wda = await this.wda();
		await wda.sendKeys(text);
	}

	public async pressButton(button: Button): Promise<void> {
		const wda = await this.wda();
		await wda.pressButton(button);
	}

	public async tap(x: number, y: number): Promise<void> {
		const wda = await this.wda();
		await wda.tap(x, y);
	}

	public async getElementsOnScreen(): Promise<ScreenElement[]> {
		const wda = await this.wda();
		return await wda.getElementsOnScreen();
	}

	public async getScreenshot(): Promise<Buffer> {
		const wda = await this.wda();
		return await wda.getScreenshot();

		/* alternative:
		await this.assertTunnelRunning();
		const tmpFilename = path.join(tmpdir(), `screenshot-${randomBytes(8).toString("hex")}.png`);
		await this.ios("screenshot", "--output", tmpFilename);
		const buffer = readFileSync(tmpFilename);
		unlinkSync(tmpFilename);
		return buffer;
		*/
	}

	public async setOrientation(orientation: Orientation): Promise<void> {
		const wda = await this.wda();
		await wda.setOrientation(orientation);
	}

	public async getOrientation(): Promise<Orientation> {
		const wda = await this.wda();
		return await wda.getOrientation();
	}
}

export class IosManager {

	public isGoIosInstalled(): boolean {
		try {
			const output = execFileSync(getGoIosPath(), ["version"], { stdio: ["pipe", "pipe", "ignore"] }).toString();
			const json: VersionCommandOutput = JSON.parse(output);
			return json.version !== undefined && (json.version.startsWith("v") || json.version === "local-build");
		} catch (error) {
			return false;
		}
	}

	public getDeviceName(deviceId: string): string {
		const output = execFileSync(getGoIosPath(), ["info", "--udid", deviceId]).toString();
		const json: InfoCommandOutput = JSON.parse(output);
		return json.DeviceName;
	}

	public listDevices(): IosDevice[] {
		if (!this.isGoIosInstalled()) {
			console.error("go-ios is not installed, no physical iOS devices can be detected");
			return [];
		}

		const output = execFileSync(getGoIosPath(), ["list"]).toString();
		const json: ListCommandOutput = JSON.parse(output);
		const devices = json.deviceList.map(device => ({
			deviceId: device,
			deviceName: this.getDeviceName(device),
		}));

		return devices;
	}
}



================================================
FILE: src/iphone-simulator.ts
================================================
import { execFileSync } from "node:child_process";

import { trace } from "./logger";
import { WebDriverAgent } from "./webdriver-agent";
import { ActionableError, Button, InstalledApp, Robot, ScreenElement, ScreenSize, SwipeDirection, Orientation } from "./robot";

export interface Simulator {
	name: string;
	uuid: string;
	state: string;
}

interface ListDevicesResponse {
	devices: {
		[key: string]: Array<{
			state: string;
			name: string;
			isAvailable: boolean;
			udid: string;
		}>,
	},
}

interface AppInfo {
	ApplicationType: string;
	Bundle: string;
	CFBundleDisplayName: string;
	CFBundleExecutable: string;
	CFBundleIdentifier: string;
	CFBundleName: string;
	CFBundleVersion: string;
	DataContainer: string;
	Path: string;
}

const TIMEOUT = 30000;
const WDA_PORT = 8100;
const MAX_BUFFER_SIZE = 1024 * 1024 * 4;

export class Simctl implements Robot {

	constructor(private readonly simulatorUuid: string) {}

	private async isWdaInstalled(): Promise<boolean> {
		const apps = await this.listApps();
		return apps.map(app => app.packageName).includes("com.facebook.WebDriverAgentRunner.xctrunner");
	}

	private async startWda(): Promise<void> {
		if (!(await this.isWdaInstalled())) {
			// wda is not even installed, won't attempt to start it
			return;
		}

		trace("Starting WebDriverAgent");
		const webdriverPackageName = "com.facebook.WebDriverAgentRunner.xctrunner";
		this.simctl("launch", this.simulatorUuid, webdriverPackageName);

		// now we wait for wda to have a successful status
		const wda = new WebDriverAgent("localhost", WDA_PORT);

		// wait up to 10 seconds for wda to start
		const timeout = +new Date() + 10 * 1000;
		while (+new Date() < timeout) {
			// cross fingers and see if wda is already running
			if (await wda.isRunning()) {
				trace("WebDriverAgent is now running");
				return;
			}

			// wait 100ms before trying again
			await new Promise(resolve => setTimeout(resolve, 100));
		}

		trace("Could not start WebDriverAgent in time, giving up");
	}

	private async wda(): Promise<WebDriverAgent> {
		const wda = new WebDriverAgent("localhost", WDA_PORT);

		if (!(await wda.isRunning())) {
			await this.startWda();
			if (!(await wda.isRunning())) {
				throw new ActionableError("WebDriverAgent is not running on simulator, please see https://github.com/mobile-next/mobile-mcp/wiki/");
			}

			// was successfully started
		}

		return wda;
	}

	private simctl(...args: string[]): Buffer {
		return execFileSync("xcrun", ["simctl", ...args], {
			timeout: TIMEOUT,
			maxBuffer: MAX_BUFFER_SIZE,
		});
	}

	public async getScreenshot(): Promise<Buffer> {
		const wda = await this.wda();
		return await wda.getScreenshot();
		// alternative: return this.simctl("io", this.simulatorUuid, "screenshot", "-");
	}

	public async openUrl(url: string) {
		const wda = await this.wda();
		await wda.openUrl(url);
		// alternative: this.simctl("openurl", this.simulatorUuid, url);
	}

	public async launchApp(packageName: string) {
		this.simctl("launch", this.simulatorUuid, packageName);
	}

	public async terminateApp(packageName: string) {
		this.simctl("terminate", this.simulatorUuid, packageName);
	}

	public async listApps(): Promise<InstalledApp[]> {
		const text = this.simctl("listapps", this.simulatorUuid).toString();
		const result = execFileSync("plutil", ["-convert", "json", "-o", "-", "-r", "-"], {
			input: text,
		});

		const output = JSON.parse(result.toString()) as Record<string, AppInfo>;
		return Object.values(output).map(app => ({
			packageName: app.CFBundleIdentifier,
			appName: app.CFBundleDisplayName,
		}));
	}

	public async getScreenSize(): Promise<ScreenSize> {
		const wda = await this.wda();
		return wda.getScreenSize();
	}

	public async sendKeys(keys: string) {
		const wda = await this.wda();
		return wda.sendKeys(keys);
	}

	public async swipe(direction: SwipeDirection): Promise<void> {
		const wda = await this.wda();
		return wda.swipe(direction);
	}

	public async swipeFromCoordinate(x: number, y: number, direction: SwipeDirection, distance?: number): Promise<void> {
		const wda = await this.wda();
		return wda.swipeFromCoordinate(x, y, direction, distance);
	}

	public async tap(x: number, y: number) {
		const wda = await this.wda();
		return wda.tap(x, y);
	}

	public async pressButton(button: Button) {
		const wda = await this.wda();
		return wda.pressButton(button);
	}

	public async getElementsOnScreen(): Promise<ScreenElement[]> {
		const wda = await this.wda();
		return wda.getElementsOnScreen();
	}

	public async setOrientation(orientation: Orientation): Promise<void> {
		const wda = await this.wda();
		return wda.setOrientation(orientation);
	}

	public async getOrientation(): Promise<Orientation> {
		const wda = await this.wda();
		return wda.getOrientation();
	}
}

export class SimctlManager {

	public listSimulators(): Simulator[] {
		// detect if this is a mac
		if (process.platform !== "darwin") {
			// don't even try to run xcrun
			return [];
		}

		try {
			const text = execFileSync("xcrun", ["simctl", "list", "devices", "-j"]).toString();
			const json: ListDevicesResponse = JSON.parse(text);
			return Object.values(json.devices).flatMap(device => {
				return device.map(d => {
					return {
						name: d.name,
						uuid: d.udid,
						state: d.state,
					};
				});
			});
		} catch (error) {
			console.error("Error listing simulators", error);
			return [];
		}
	}

	public listBootedSimulators(): Simulator[] {
		return this.listSimulators()
			.filter(simulator => simulator.state === "Booted");
	}

	public getSimulator(uuid: string): Simctl {
		return new Simctl(uuid);
	}
}



================================================
FILE: src/logger.ts
================================================
import { appendFileSync } from "node:fs";

const writeLog = (message: string) => {
	if (process.env.LOG_FILE) {
		const logfile = process.env.LOG_FILE;
		const timestamp = new Date().toISOString();
		const levelStr = "INFO";
		const logMessage = `[${timestamp}] ${levelStr} ${message}`;
		appendFileSync(logfile, logMessage + "\n");
	}

	console.error(message);
};

export const trace = (message: string) => {
	writeLog(message);
};

export const error = (message: string) => {
	writeLog(message);
};



================================================
FILE: src/png.ts
================================================
export interface PngDimensions {
	width: number;
	height: number;
}

export class PNG {
	public constructor(private readonly buffer: Buffer) {
	}

	public getDimensions(): PngDimensions {
		const pngSignature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
		if (!this.buffer.subarray(0, 8).equals(pngSignature)) {
			throw new Error("Not a valid PNG file");
		}

		const width = this.buffer.readUInt32BE(16);
		const height = this.buffer.readUInt32BE(20);
		return { width, height };
	}
}



================================================
FILE: src/robot.ts
================================================
export interface Dimensions {
	width: number;
	height: number;
}

export interface ScreenSize extends Dimensions {
	scale: number;
}

export interface InstalledApp {
	packageName: string;
	appName: string;
}

export type SwipeDirection = "up" | "down" | "left" | "right";

export type Button = "HOME" | "BACK" | "VOLUME_UP" | "VOLUME_DOWN" | "ENTER" | "DPAD_CENTER" | "DPAD_UP" | "DPAD_DOWN" | "DPAD_LEFT" | "DPAD_RIGHT";

export interface ScreenElementRect {
	x: number;
	y: number;
	width: number;
	height: number;
}

export interface ScreenElement {
	type: string;
	label?: string;
	text?: string;
	name?: string;
	value?: string;
	identifier?: string;
	rect: ScreenElementRect;

	// currently only on android tv
	focused?: boolean;
}

export class ActionableError extends Error {
	constructor(message: string) {
		super(message);
	}
}

export type Orientation = "portrait" | "landscape";

export interface Robot {
	/**
	 * Get the screen size of the device in pixels.
	 */
	getScreenSize(): Promise<ScreenSize>;

	/**
	 * Swipe in a direction.
	 */
	swipe(direction: SwipeDirection): Promise<void>;

	/**
	 * Swipe from a specific coordinate in a direction.
	 */
	swipeFromCoordinate(x: number, y: number, direction: SwipeDirection, distance?: number): Promise<void>;

	/**
	 * Get a screenshot of the screen. Returns a Buffer that contains
	 * a PNG image of the screen. Will be same dimensions as getScreenSize().
	 */
	getScreenshot(): Promise<Buffer>;

	/**
	 * List all installed apps on the device. Returns an array of package names (or
	 * bundle identifiers in iOS) for all installed apps.
	 */
	listApps(): Promise<InstalledApp[]>;

	/**
	 * Launch an app.
	 */
	launchApp(packageName: string): Promise<void>;

	/**
	 * Terminate an app. If app was already terminated (or non existent) then this
	 * is a no-op.
	 */
	terminateApp(packageName: string): Promise<void>;

	/**
	 * Open a URL in the device's web browser. Can be an https:// url, or a
	 * custom scheme (e.g. "myapp://").
	 */
	openUrl(url: string): Promise<void>;

	/**
	 * Send keys to the device, simulating keyboard input.
	 */
	sendKeys(text: string): Promise<void>;

	/**
	 * Press a button on the device, simulating a physical button press.
	 */
	pressButton(button: Button): Promise<void>;

	/**
	 * Tap on a specific coordinate on the screen.
	 */
	tap(x: number, y: number): Promise<void>;

	/**
	 * Get all elements on the screen. Works only on native apps (not webviews). Will
	 * return a filtered list of elements that make sense to interact with.
	 */
	getElementsOnScreen(): Promise<ScreenElement[]>;

	/**
	 * Change the screen orientation of the device.
	 * @param orientation The desired orientation ("portrait" or "landscape")
	 */
	setOrientation(orientation: Orientation): Promise<void>;

	/**
	 * Get the current screen orientation.
	 */
	getOrientation(): Promise<Orientation>;
}



================================================
FILE: src/server.ts
================================================
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { CallToolResult } from "@modelcontextprotocol/sdk/types";
import { z, ZodRawShape, ZodTypeAny } from "zod";
import fs from "node:fs";
import os from "node:os";
import crypto from "node:crypto";

import { error, trace } from "./logger";
import { AndroidRobot, AndroidDeviceManager } from "./android";
import { ActionableError, Robot } from "./robot";
import { SimctlManager } from "./iphone-simulator";
import { IosManager, IosRobot } from "./ios";
import { PNG } from "./png";
import { isImageMagickInstalled, Image } from "./image-utils";

export const getAgentVersion = (): string => {
	const json = require("../package.json");
	return json.version;
};

const getLatestAgentVersion = async (): Promise<string> => {
	const response = await fetch("https://api.github.com/repos/mobile-next/mobile-mcp/tags?per_page=1");
	const json = await response.json();
	return json[0].name;
};

const checkForLatestAgentVersion = async (): Promise<void> => {
	try {
		const latestVersion = await getLatestAgentVersion();
		const currentVersion = getAgentVersion();
		if (latestVersion !== currentVersion) {
			trace(`You are running an older version of the agent. Please update to the latest version: ${latestVersion}.`);
		}
	} catch (error: any) {
		// ignore
	}
};

export const createMcpServer = (): McpServer => {

	const server = new McpServer({
		name: "mobile-mcp",
		version: getAgentVersion(),
		capabilities: {
			resources: {},
			tools: {},
		},
	});

	// an empty object to satisfy windsurf
	const noParams = z.object({});

	const tool = (name: string, description: string, paramsSchema: ZodRawShape, cb: (args: z.objectOutputType<ZodRawShape, ZodTypeAny>) => Promise<string>) => {
		const wrappedCb = async (args: ZodRawShape): Promise<CallToolResult> => {
			try {
				trace(`Invoking ${name} with args: ${JSON.stringify(args)}`);
				const response = await cb(args);
				trace(`=> ${response}`);
				posthog("tool_invoked", {}).then();
				return {
					content: [{ type: "text", text: response }],
				};
			} catch (error: any) {
				if (error instanceof ActionableError) {
					return {
						content: [{ type: "text", text: `${error.message}. Please fix the issue and try again.` }],
					};
				} else {
					// a real exception
					trace(`Tool '${description}' failed: ${error.message} stack: ${error.stack}`);
					return {
						content: [{ type: "text", text: `Error: ${error.message}` }],
						isError: true,
					};
				}
			}
		};

		server.tool(name, description, paramsSchema, args => wrappedCb(args));
	};

	const posthog = async (event: string, properties: Record<string, string>) => {
		try {
			const url = "https://us.i.posthog.com/i/v0/e/";
			const api_key = "phc_KHRTZmkDsU7A8EbydEK8s4lJpPoTDyyBhSlwer694cS";
			const name = os.hostname() + process.execPath;
			const distinct_id = crypto.createHash("sha256").update(name).digest("hex");
			const systemProps = {
				Platform: os.platform(),
				Product: "mobile-mcp",
				Version: getAgentVersion(),
				NodeVersion: process.version,
			};

			await fetch(url, {
				method: "POST",
				headers: {
					"Content-Type": "application/json"
				},
				body: JSON.stringify({
					api_key,
					event,
					properties: {
						...systemProps,
						...properties,
					},
					distinct_id,
				})
			});
		} catch (err: any) {
			// ignore
		}
	};

	posthog("launch", {}).then();

	let robot: Robot | null;
	const simulatorManager = new SimctlManager();

	const requireRobot = () => {
		if (!robot) {
			throw new ActionableError("No device selected. Use the mobile_use_device tool to select a device.");
		}
	};

	tool(
		"mobile_use_default_device",
		"Use the default device. This is a shortcut for mobile_use_device with deviceType=simulator and device=simulator_name",
		{
			noParams
		},
		async () => {
			const iosManager = new IosManager();
			const androidManager = new AndroidDeviceManager();
			const simulators = simulatorManager.listBootedSimulators();
			const androidDevices = androidManager.getConnectedDevices();
			const iosDevices = iosManager.listDevices();

			const sum = simulators.length + androidDevices.length + iosDevices.length;
			if (sum === 0) {
				throw new ActionableError("No devices found. Please connect a device and try again.");
			} else if (sum >= 2) {
				throw new ActionableError("Multiple devices found. Please use the mobile_list_available_devices tool to list available devices and select one.");
			}

			// only one device connected, let's find it now
			if (simulators.length === 1) {
				robot = simulatorManager.getSimulator(simulators[0].name);
				return `Selected default device: ${simulators[0].name}`;
			} else if (androidDevices.length === 1) {
				robot = new AndroidRobot(androidDevices[0].deviceId);
				return `Selected default device: ${androidDevices[0].deviceId}`;
			} else if (iosDevices.length === 1) {
				robot = new IosRobot(iosDevices[0].deviceId);
				return `Selected default device: ${iosDevices[0].deviceId}`;
			}

			// how did this happen?
			throw new ActionableError("No device selected. Please use the mobile_list_available_devices tool to list available devices and select one.");
		}
	);

	tool(
		"mobile_list_available_devices",
		"List all available devices. This includes both physical devices and simulators. If there is more than one device returned, you need to let the user select one of them.",
		{
			noParams
		},
		async ({}) => {
			const iosManager = new IosManager();
			const androidManager = new AndroidDeviceManager();
			const simulators = simulatorManager.listBootedSimulators();
			const simulatorNames = simulators.map(d => d.name);
			const androidDevices = androidManager.getConnectedDevices();
			const iosDevices = await iosManager.listDevices();
			const iosDeviceNames = iosDevices.map(d => d.deviceId);
			const androidTvDevices = androidDevices.filter(d => d.deviceType === "tv").map(d => d.deviceId);
			const androidMobileDevices = androidDevices.filter(d => d.deviceType === "mobile").map(d => d.deviceId);

			const resp = ["Found these devices:"];
			if (simulatorNames.length > 0) {
				resp.push(`iOS simulators: [${simulatorNames.join(".")}]`);
			}

			if (iosDevices.length > 0) {
				resp.push(`iOS devices: [${iosDeviceNames.join(",")}]`);
			}

			if (androidMobileDevices.length > 0) {
				resp.push(`Android devices: [${androidMobileDevices.join(",")}]`);
			}

			if (androidTvDevices.length > 0) {
				resp.push(`Android TV devices: [${androidTvDevices.join(",")}]`);
			}

			return resp.join("\n");
		}
	);

	tool(
		"mobile_use_device",
		"Select a device to use. This can be a simulator or an Android device. Use the list_available_devices tool to get a list of available devices.",
		{
			device: z.string().describe("The name of the device to select"),
			deviceType: z.enum(["simulator", "ios", "android"]).describe("The type of device to select"),
		},
		async ({ device, deviceType }) => {
			switch (deviceType) {
				case "simulator":
					robot = simulatorManager.getSimulator(device);
					break;
				case "ios":
					robot = new IosRobot(device);
					break;
				case "android":
					robot = new AndroidRobot(device);
					break;
			}

			return `Selected device: ${device}`;
		}
	);

	tool(
		"mobile_list_apps",
		"List all the installed apps on the device",
		{
			noParams
		},
		async ({}) => {
			requireRobot();
			const result = await robot!.listApps();
			return `Found these apps on device: ${result.map(app => `${app.appName} (${app.packageName})`).join(", ")}`;
		}
	);

	tool(
		"mobile_launch_app",
		"Launch an app on mobile device. Use this to open a specific app. You can find the package name of the app by calling list_apps_on_device.",
		{
			packageName: z.string().describe("The package name of the app to launch"),
		},
		async ({ packageName }) => {
			requireRobot();
			await robot!.launchApp(packageName);
			return `Launched app ${packageName}`;
		}
	);

	tool(
		"mobile_terminate_app",
		"Stop and terminate an app on mobile device",
		{
			packageName: z.string().describe("The package name of the app to terminate"),
		},
		async ({ packageName }) => {
			requireRobot();
			await robot!.terminateApp(packageName);
			return `Terminated app ${packageName}`;
		}
	);

	tool(
		"mobile_get_screen_size",
		"Get the screen size of the mobile device in pixels",
		{
			noParams
		},
		async ({}) => {
			requireRobot();
			const screenSize = await robot!.getScreenSize();
			return `Screen size is ${screenSize.width}x${screenSize.height} pixels`;
		}
	);

	tool(
		"mobile_click_on_screen_at_coordinates",
		"Click on the screen at given x,y coordinates. If clicking on an element, use the list_elements_on_screen tool to find the coordinates.",
		{
			x: z.number().describe("The x coordinate to click on the screen, in pixels"),
			y: z.number().describe("The y coordinate to click on the screen, in pixels"),
		},
		async ({ x, y }) => {
			requireRobot();
			await robot!.tap(x, y);
			return `Clicked on screen at coordinates: ${x}, ${y}`;
		}
	);

	tool(
		"mobile_list_elements_on_screen",
		"List elements on screen and their coordinates, with display text or accessibility label. Do not cache this result.",
		{
			noParams
		},
		async ({}) => {
			requireRobot();
			const elements = await robot!.getElementsOnScreen();

			const result = elements.map(element => {
				const out: any = {
					type: element.type,
					text: element.text,
					label: element.label,
					name: element.name,
					value: element.value,
					identifier: element.identifier,
					coordinates: {
						x: element.rect.x,
						y: element.rect.y,
						width: element.rect.width,
						height: element.rect.height,
					},
				};

				if (element.focused) {
					out.focused = true;
				}

				return out;
			});

			return `Found these elements on screen: ${JSON.stringify(result)}`;
		}
	);

	tool(
		"mobile_press_button",
		"Press a button on device",
		{
			button: z.string().describe("The button to press. Supported buttons: BACK (android only), HOME, VOLUME_UP, VOLUME_DOWN, ENTER, DPAD_CENTER (android tv only), DPAD_UP (android tv only), DPAD_DOWN (android tv only), DPAD_LEFT (android tv only), DPAD_RIGHT (android tv only)"),
		},
		async ({ button }) => {
			requireRobot();
			await robot!.pressButton(button);
			return `Pressed the button: ${button}`;
		}
	);

	tool(
		"mobile_open_url",
		"Open a URL in browser on device",
		{
			url: z.string().describe("The URL to open"),
		},
		async ({ url }) => {
			requireRobot();
			await robot!.openUrl(url);
			return `Opened URL: ${url}`;
		}
	);

	tool(
		"swipe_on_screen",
		"Swipe on the screen",
		{
			direction: z.enum(["up", "down", "left", "right"]).describe("The direction to swipe"),
			x: z.number().optional().describe("The x coordinate to start the swipe from, in pixels. If not provided, uses center of screen"),
			y: z.number().optional().describe("The y coordinate to start the swipe from, in pixels. If not provided, uses center of screen"),
			distance: z.number().optional().describe("The distance to swipe in pixels. Defaults to 400 pixels for iOS or 30% of screen dimension for Android"),
		},
		async ({ direction, x, y, distance }) => {
			requireRobot();

			if (x !== undefined && y !== undefined) {
				// Use coordinate-based swipe
				await robot!.swipeFromCoordinate(x, y, direction, distance);
				const distanceText = distance ? ` ${distance} pixels` : "";
				return `Swiped ${direction}${distanceText} from coordinates: ${x}, ${y}`;
			} else {
				// Use center-based swipe
				await robot!.swipe(direction);
				return `Swiped ${direction} on screen`;
			}
		}
	);

	tool(
		"mobile_type_keys",
		"Type text into the focused element",
		{
			text: z.string().describe("The text to type"),
			submit: z.boolean().describe("Whether to submit the text. If true, the text will be submitted as if the user pressed the enter key."),
		},
		async ({ text, submit }) => {
			requireRobot();
			await robot!.sendKeys(text);

			if (submit) {
				await robot!.pressButton("ENTER");
			}

			return `Typed text: ${text}`;
		}
	);

	tool(
		"mobile_save_screenshot",
		"Save a screenshot of the mobile device to a file",
		{
			saveTo: z.string().describe("The path to save the screenshot to"),
		},
		async ({ saveTo }) => {
			requireRobot();

			const screenshot = await robot!.getScreenshot();
			fs.writeFileSync(saveTo, screenshot);
			return `Screenshot saved to: ${saveTo}`;
		}
	);

	server.tool(
		"mobile_take_screenshot",
		"Take a screenshot of the mobile device. Use this to understand what's on screen, if you need to press an element that is available through view hierarchy then you must list elements on screen instead. Do not cache this result.",
		{
			noParams
		},
		async ({}) => {
			requireRobot();

			try {
				const screenSize = await robot!.getScreenSize();

				let screenshot = await robot!.getScreenshot();
				let mimeType = "image/png";

				// validate we received a png, will throw exception otherwise
				const image = new PNG(screenshot);
				const pngSize = image.getDimensions();
				if (pngSize.width <= 0 || pngSize.height <= 0) {
					throw new ActionableError("Screenshot is invalid. Please try again.");
				}

				if (isImageMagickInstalled()) {
					trace("ImageMagick is installed, resizing screenshot");
					const image = Image.fromBuffer(screenshot);
					const beforeSize = screenshot.length;
					screenshot = image.resize(Math.floor(pngSize.width / screenSize.scale))
						.jpeg({ quality: 75 })
						.toBuffer();

					const afterSize = screenshot.length;
					trace(`Screenshot resized from ${beforeSize} bytes to ${afterSize} bytes`);

					mimeType = "image/jpeg";
				}

				const screenshot64 = screenshot.toString("base64");
				trace(`Screenshot taken: ${screenshot.length} bytes`);

				return {
					content: [{ type: "image", data: screenshot64, mimeType }]
				};
			} catch (err: any) {
				error(`Error taking screenshot: ${err.message} ${err.stack}`);
				return {
					content: [{ type: "text", text: `Error: ${err.message}` }],
					isError: true,
				};
			}
		}
	);

	tool(
		"mobile_set_orientation",
		"Change the screen orientation of the device",
		{
			orientation: z.enum(["portrait", "landscape"]).describe("The desired orientation"),
		},
		async ({ orientation }) => {
			requireRobot();
			await robot!.setOrientation(orientation);
			return `Changed device orientation to ${orientation}`;
		}
	);

	tool(
		"mobile_get_orientation",
		"Get the current screen orientation of the device",
		{
			noParams
		},
		async () => {
			requireRobot();
			const orientation = await robot!.getOrientation();
			return `Current device orientation is ${orientation}`;
		}
	);

	// async check for latest agent version
	checkForLatestAgentVersion().then();

	return server;
};



================================================
FILE: src/webdriver-agent.ts
================================================
import { ActionableError, SwipeDirection, ScreenSize, ScreenElement, Orientation } from "./robot";

export interface SourceTreeElementRect {
	x: number;
	y: number;
	width: number;
	height: number;
}

export interface SourceTreeElement {
	type: string;
	label?: string;
	name?: string;
	value?: string;
	rawIdentifier?: string;
	rect: SourceTreeElementRect;
	isVisible?: string; // "0" or "1"
	children?: Array<SourceTreeElement>;
}

export interface SourceTree {
	value: SourceTreeElement;
}

export class WebDriverAgent {

	constructor(private readonly host: string, private readonly port: number) {
	}

	public async isRunning(): Promise<boolean> {
		const url = `http://${this.host}:${this.port}/status`;
		try {
			const response = await fetch(url);
			const json = await response.json();
			return response.status === 200 && json.value?.ready === true;
		} catch (error) {
			// console.error(`Failed to connect to WebDriverAgent: ${error}`);
			return false;
		}
	}

	public async createSession(): Promise<string> {
		const url = `http://${this.host}:${this.port}/session`;
		const response = await fetch(url, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: JSON.stringify({ capabilities: { alwaysMatch: { platformName: "iOS" } } }),
		});

		if (!response.ok) {
			const errorText = await response.text();
			throw new ActionableError(`Failed to create WebDriver session: ${response.status} ${errorText}`);
		}

		const json = await response.json();
		if (!json.value || !json.value.sessionId) {
			throw new ActionableError(`Invalid session response: ${JSON.stringify(json)}`);
		}

		return json.value.sessionId;
	}

	public async deleteSession(sessionId: string) {
		const url = `http://${this.host}:${this.port}/session/${sessionId}`;
		const response = await fetch(url, { method: "DELETE" });
		return response.json();
	}

	public async withinSession(fn: (url: string) => Promise<any>) {
		const sessionId = await this.createSession();
		const url = `http://${this.host}:${this.port}/session/${sessionId}`;
		const result = await fn(url);
		await this.deleteSession(sessionId);
		return result;
	}

	public async getScreenSize(sessionUrl?: string): Promise<ScreenSize> {
		if (sessionUrl) {
			const url = `${sessionUrl}/wda/screen`;
			const response = await fetch(url);
			const json = await response.json();
			return {
				width: json.value.screenSize.width,
				height: json.value.screenSize.height,
				scale: json.value.scale || 1,
			};
		} else {
			return this.withinSession(async sessionUrlInner => {
				const url = `${sessionUrlInner}/wda/screen`;
				const response = await fetch(url);
				const json = await response.json();
				return {
					width: json.value.screenSize.width,
					height: json.value.screenSize.height,
					scale: json.value.scale || 1,
				};
			});
		}
	}

	public async sendKeys(keys: string) {
		await this.withinSession(async sessionUrl => {
			const url = `${sessionUrl}/wda/keys`;
			await fetch(url, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify({ value: [keys] }),
			});
		});
	}

	public async pressButton(button: string) {
		const _map = {
			"HOME": "home",
			"VOLUME_UP": "volumeup",
			"VOLUME_DOWN": "volumedown",
		};

		if (button === "ENTER") {
			await this.sendKeys("\n");
			return;
		}

		// Type assertion to check if button is a key of _map
		if (!(button in _map)) {
			throw new ActionableError(`Button "${button}" is not supported`);
		}

		await this.withinSession(async sessionUrl => {
			const url = `${sessionUrl}/wda/pressButton`;
			const response = await fetch(url, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify({
					name: button,
				}),
			});

			return response.json();
		});
	}

	public async tap(x: number, y: number) {
		await this.withinSession(async sessionUrl => {
			const url = `${sessionUrl}/actions`;
			await fetch(url, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify({
					actions: [
						{
							type: "pointer",
							id: "finger1",
							parameters: { pointerType: "touch" },
							actions: [
								{ type: "pointerMove", duration: 0, x, y },
								{ type: "pointerDown", button: 0 },
								{ type: "pause", duration: 100 },
								{ type: "pointerUp", button: 0 }
							]
						}
					]
				}),
			});
		});
	}

	private isVisible(rect: SourceTreeElementRect): boolean {
		return rect.x >= 0 && rect.y >= 0;
	}

	private filterSourceElements(source: SourceTreeElement): Array<ScreenElement> {
		const output: ScreenElement[] = [];

		const acceptedTypes = ["TextField", "Button", "Switch", "Icon", "SearchField", "StaticText", "Image"];

		if (acceptedTypes.includes(source.type)) {
			if (source.isVisible === "1" && this.isVisible(source.rect)) {
				if (source.label !== null || source.name !== null || source.rawIdentifier !== null) {
					output.push({
						type: source.type,
						label: source.label,
						name: source.name,
						value: source.value,
						identifier: source.rawIdentifier,
						rect: {
							x: source.rect.x,
							y: source.rect.y,
							width: source.rect.width,
							height: source.rect.height,
						},
					});
				}
			}
		}

		if (source.children) {
			for (const child of source.children) {
				output.push(...this.filterSourceElements(child));
			}
		}

		return output;
	}

	public async getPageSource(): Promise<SourceTree> {
		const url = `http://${this.host}:${this.port}/source/?format=json`;
		const response = await fetch(url);
		const json = await response.json();
		return json as SourceTree;
	}

	public async getElementsOnScreen(): Promise<ScreenElement[]> {
		const source = await this.getPageSource();
		return this.filterSourceElements(source.value);
	}

	public async openUrl(url: string): Promise<void> {
		await this.withinSession(async sessionUrl => {
			await fetch(`${sessionUrl}/url`, {
				method: "POST",
				body: JSON.stringify({ url }),
			});
		});
	}

	public async getScreenshot(): Promise<Buffer> {
		const url = `http://${this.host}:${this.port}/screenshot`;
		const response = await fetch(url);
		const json = await response.json();
		return Buffer.from(json.value, "base64");
	}

	public async swipe(direction: SwipeDirection): Promise<void> {
		await this.withinSession(async sessionUrl => {
			const screenSize = await this.getScreenSize(sessionUrl);
			let x0: number, y0: number, x1: number, y1: number;
			// Use 60% of the width/height for swipe distance
			const verticalDistance = Math.floor(screenSize.height * 0.6);
			const horizontalDistance = Math.floor(screenSize.width * 0.6);
			const centerX = Math.floor(screenSize.width / 2);
			const centerY = Math.floor(screenSize.height / 2);

			switch (direction) {
				case "up":
					x0 = x1 = centerX;
					y0 = centerY + Math.floor(verticalDistance / 2);
					y1 = centerY - Math.floor(verticalDistance / 2);
					break;
				case "down":
					x0 = x1 = centerX;
					y0 = centerY - Math.floor(verticalDistance / 2);
					y1 = centerY + Math.floor(verticalDistance / 2);
					break;
				case "left":
					y0 = y1 = centerY;
					x0 = centerX + Math.floor(horizontalDistance / 2);
					x1 = centerX - Math.floor(horizontalDistance / 2);
					break;
				case "right":
					y0 = y1 = centerY;
					x0 = centerX - Math.floor(horizontalDistance / 2);
					x1 = centerX + Math.floor(horizontalDistance / 2);
					break;
				default:
					throw new ActionableError(`Swipe direction "${direction}" is not supported`);
			}

			const url = `${sessionUrl}/actions`;
			const response = await fetch(url, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify({
					actions: [
						{
							type: "pointer",
							id: "finger1",
							parameters: { pointerType: "touch" },
							actions: [
								{ type: "pointerMove", duration: 0, x: x0, y: y0 },
								{ type: "pointerDown", button: 0 },
								{ type: "pointerMove", duration: 1000, x: x1, y: y1 },
								{ type: "pointerUp", button: 0 }
							]
						}
					]
				}),
			});

			if (!response.ok) {
				const errorText = await response.text();
				throw new ActionableError(`WebDriver actions request failed: ${response.status} ${errorText}`);
			}

			// Clear actions to ensure they complete
			await fetch(`${sessionUrl}/actions`, {
				method: "DELETE",
			});
		});
	}

	public async swipeFromCoordinate(x: number, y: number, direction: SwipeDirection, distance: number = 400): Promise<void> {
		await this.withinSession(async sessionUrl => {
			// Use simple coordinates like the working swipe method
			const x0 = x;
			const y0 = y;
			let x1 = x;
			let y1 = y;

			// Calculate target position based on direction and distance
			switch (direction) {
				case "up":
					y1 = y - distance; // Move up by specified distance
					break;
				case "down":
					y1 = y + distance; // Move down by specified distance
					break;
				case "left":
					x1 = x - distance; // Move left by specified distance
					break;
				case "right":
					x1 = x + distance; // Move right by specified distance
					break;
				default:
					throw new ActionableError(`Swipe direction "${direction}" is not supported`);
			}

			const url = `${sessionUrl}/actions`;
			const response = await fetch(url, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify({
					actions: [
						{
							type: "pointer",
							id: "finger1",
							parameters: { pointerType: "touch" },
							actions: [
								{ type: "pointerMove", duration: 0, x: x0, y: y0 },
								{ type: "pointerDown", button: 0 },
								{ type: "pointerMove", duration: 1000, x: x1, y: y1 },
								{ type: "pointerUp", button: 0 }
							]
						}
					]
				}),
			});

			if (!response.ok) {
				const errorText = await response.text();
				throw new ActionableError(`WebDriver actions request failed: ${response.status} ${errorText}`);
			}

			// Clear actions to ensure they complete
			await fetch(`${sessionUrl}/actions`, {
				method: "DELETE",
			});
		});
	}

	public async setOrientation(orientation: Orientation): Promise<void> {
		await this.withinSession(async sessionUrl => {
			const url = `${sessionUrl}/orientation`;
			await fetch(url, {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({
					orientation: orientation.toUpperCase()
				})
			});
		});
	}

	public async getOrientation(): Promise<Orientation> {
		return this.withinSession(async sessionUrl => {
			const url = `${sessionUrl}/orientation`;
			const response = await fetch(url);
			const json = await response.json();
			return json.value.toLowerCase() as Orientation;
		});
	}
}



================================================
FILE: test/android.ts
================================================
import assert from "node:assert";

import { PNG } from "../src/png";
import { AndroidRobot, AndroidDeviceManager } from "../src/android";

const manager = new AndroidDeviceManager();
const devices = manager.getConnectedDevices();
const hasOneAndroidDevice = devices.length === 1;

describe("android", () => {

	const android = new AndroidRobot(devices?.[0]?.deviceId || "");

	it("should be able to get the screen size", async function() {
		hasOneAndroidDevice || this.skip();
		const screenSize = await android.getScreenSize();
		assert.ok(screenSize.width > 1024);
		assert.ok(screenSize.height > 1024);
		assert.ok(screenSize.scale === 1);
		assert.equal(Object.keys(screenSize).length, 3, "screenSize should have exactly 3 properties");
	});

	it("should be able to take screenshot", async function() {
		hasOneAndroidDevice || this.skip();

		const screenSize = await android.getScreenSize();
		const screenshot = await android.getScreenshot();
		assert.ok(screenshot.length > 64 * 1024);

		// must be a valid png image that matches the screen size
		const image = new PNG(screenshot);
		const pngSize = image.getDimensions();
		assert.equal(pngSize.width, screenSize.width);
		assert.equal(pngSize.height, screenSize.height);
	});

	it("should be able to list apps", async function() {
		hasOneAndroidDevice || this.skip();
		const apps = await android.listApps();
		const packages = apps.map(app => app.packageName);
		assert.ok(packages.includes("com.android.settings"));
	});

	it("should be able to open a url", async function() {
		hasOneAndroidDevice || this.skip();
		await android.adb("shell", "input", "keyevent", "HOME");
		await android.openUrl("https://www.example.com");
	});

	it("should be able to list elements on screen", async function() {
		hasOneAndroidDevice || this.skip();
		await android.terminateApp("com.android.chrome");
		await android.adb("shell", "input", "keyevent", "HOME");
		await android.openUrl("https://www.example.com");
		const elements = await android.getElementsOnScreen();

		// make sure title (TextView) is present
		const foundTitle = elements.find(element => element.type === "android.widget.TextView" && element.text?.startsWith("This domain is for use in illustrative examples in documents"));
		assert.ok(foundTitle, "Title element not found");

		// make sure navbar (EditText) is present
		const foundNavbar = elements.find(element => element.type === "android.widget.EditText" && element.label === "Search or type URL" && element.text === "example.com");
		assert.ok(foundNavbar, "Navbar element not found");

		// this is an icon, but has accessibility label
		const foundSecureIcon = elements.find(element => element.type === "android.widget.ImageButton" && element.text === "" && element.label === "New tab");
		assert.ok(foundSecureIcon, "New tab icon not found");
	});

	it("should be able to send keys and tap", async function() {
		hasOneAndroidDevice || this.skip();
		await android.terminateApp("com.google.android.deskclock");
		await android.adb("shell", "pm", "clear", "com.google.android.deskclock");
		await android.launchApp("com.google.android.deskclock");

		// We probably start at Clock tab
		await new Promise(resolve => setTimeout(resolve, 3000));
		let elements = await android.getElementsOnScreen();
		const timerElement = elements.find(e => e.label === "Timer" && e.type === "android.widget.FrameLayout");
		assert.ok(timerElement !== undefined);
		await android.tap(timerElement.rect.x, timerElement.rect.y);

		// now we're in Timer tab
		await new Promise(resolve => setTimeout(resolve, 3000));
		elements = await android.getElementsOnScreen();
		const currentTime = elements.find(e => e.text === "00h 00m 00s");
		assert.ok(currentTime !== undefined, "Expected time to be 00h 00m 00s");
		await android.sendKeys("123456");

		// now the title has changed with new timer
		await new Promise(resolve => setTimeout(resolve, 3000));
		elements = await android.getElementsOnScreen();
		const newTime = elements.find(e => e.text === "12h 34m 56s");
		assert.ok(newTime !== undefined, "Expected time to be 12h 34m 56s");

		await android.terminateApp("com.google.android.deskclock");
	});

	it("should be able to launch and terminate an app", async function() {
		hasOneAndroidDevice || this.skip();

		// kill if running
		await android.terminateApp("com.android.chrome");

		await android.launchApp("com.android.chrome");
		await new Promise(resolve => setTimeout(resolve, 3000));
		const processes = await android.listRunningProcesses();
		assert.ok(processes.includes("com.android.chrome"));

		await android.terminateApp("com.android.chrome");
		const processes2 = await android.listRunningProcesses();
		assert.ok(!processes2.includes("com.android.chrome"));
	});

	it("should handle orientation changes", async function() {
		hasOneAndroidDevice || this.skip();

		// assume we start in portrait
		const originalOrientation = await android.getOrientation();
		assert.equal(originalOrientation, "portrait");
		const screenSize1 = await android.getScreenSize();

		// set to landscape
		await android.setOrientation("landscape");
		await new Promise(resolve => setTimeout(resolve, 1500));
		const orientation = await android.getOrientation();
		assert.equal(orientation, "landscape");
		const screenSize2 = await android.getScreenSize();

		// set to portrait
		await android.setOrientation("portrait");
		await new Promise(resolve => setTimeout(resolve, 1500));
		const orientation2 = await android.getOrientation();
		assert.equal(orientation2, "portrait");

		// screen size should not have changed
		assert.deepEqual(screenSize1, screenSize2);
	});
});



================================================
FILE: test/ios.ts
================================================
import assert from "node:assert";

import { IosManager, IosRobot } from "../src/ios";
import { PNG } from "../src/png";

describe("ios", async () => {

	const manager = new IosManager();
	const devices = await manager.listDevices();
	const hasOneDevice = devices.length === 1;
	const robot = new IosRobot(devices?.[0]?.deviceId || "");

	it("should be able to get screenshot", async function() {
		hasOneDevice || this.skip();
		const screenshot = await robot.getScreenshot();
		// an black screenshot (screen is off) still consumes over 30KB
		assert.ok(screenshot.length > 128 * 1024);

		// must be a valid png image that matches the screen size
		const image = new PNG(screenshot);
		const pngSize = image.getDimensions();
		const screenSize = await robot.getScreenSize();

		// wda returns screen size as points, round up
		assert.equal(Math.ceil(pngSize.width / screenSize.scale), screenSize.width);
		assert.equal(Math.ceil(pngSize.height / screenSize.scale), screenSize.height);
	});
});



================================================
FILE: test/iphone-simulator.ts
================================================
import assert from "node:assert";
import { randomBytes } from "node:crypto";

import { PNG } from "../src/png";
import { SimctlManager } from "../src/iphone-simulator";

describe("iphone-simulator", () => {

	const manager = new SimctlManager();
	const bootedSimulators = manager.listBootedSimulators();
	const hasOneSimulator = bootedSimulators.length === 1;
	const simctl = manager.getSimulator(bootedSimulators?.[0]?.uuid || "");

	const restartApp = async (app: string) => {
		await simctl.launchApp(app);
		await simctl.terminateApp(app);
		await simctl.launchApp(app);
	};

	const restartPreferencesApp = async () => {
		await restartApp("com.apple.Preferences");
	};

	const restartRemindersApp = async () => {
		await restartApp("com.apple.reminders");
	};

	it("should be able to swipe", async function() {
		hasOneSimulator || this.skip();
		await restartPreferencesApp();

		// make sure "General" is present (since it's at the top of the list)
		const elements1 = await simctl.getElementsOnScreen();
		assert.ok(elements1.findIndex(e => e.name === "com.apple.settings.general") !== -1);

		// swipe up (bottom of screen to top of screen)
		await simctl.swipe("up");

		// make sure "General" is not visible now
		const elements2 = await simctl.getElementsOnScreen();
		assert.ok(elements2.findIndex(e => e.name === "com.apple.settings.general") === -1);

		// swipe down
		await simctl.swipe("down");

		// make sure "General" is visible again
		const elements3 = await simctl.getElementsOnScreen();
		assert.ok(elements3.findIndex(e => e.name === "com.apple.settings.general") !== -1);
	});

	it("should be able to send keys and press enter", async function() {
		hasOneSimulator || this.skip();
		await restartRemindersApp();

		// find new reminder element
		await new Promise(resolve => setTimeout(resolve, 3000));
		const elements = await simctl.getElementsOnScreen();
		const newElement = elements.find(e => e.label === "New Reminder");
		assert.ok(newElement !== undefined, "should have found New Reminder element");

		// click on new reminder
		await simctl.tap(newElement.rect.x, newElement.rect.y);

		// wait for keyboard to appear
		await new Promise(resolve => setTimeout(resolve, 1000));

		// send keys with press button "Enter"
		const random1 = randomBytes(8).toString("hex");
		await simctl.sendKeys(random1);
		await simctl.pressButton("ENTER");

		// send keys with "\n"
		const random2 = randomBytes(8).toString("hex");
		await simctl.sendKeys(random2 + "\n");

		const elements2 = await simctl.getElementsOnScreen();
		assert.ok(elements2.findIndex(e => e.value === random1) !== -1);
		assert.ok(elements2.findIndex(e => e.value === random2) !== -1);
	});

	it("should be able to get the screen size", async function() {
		hasOneSimulator || this.skip();
		const screenSize = await simctl.getScreenSize();
		assert.ok(screenSize.width > 256);
		assert.ok(screenSize.height > 256);
		assert.ok(screenSize.scale >= 1);
		assert.equal(Object.keys(screenSize).length, 3, "screenSize should have exactly 3 properties");
	});

	it("should be able to get screenshot", async function() {
		hasOneSimulator || this.skip();
		const screenshot = await simctl.getScreenshot();
		assert.ok(screenshot.length > 64 * 1024);

		// must be a valid png image that matches the screen size
		const image = new PNG(screenshot);
		const pngSize = image.getDimensions();
		const screenSize = await simctl.getScreenSize();

		// wda returns screen size as points, round up
		assert.equal(Math.ceil(pngSize.width / screenSize.scale), screenSize.width);
		assert.equal(Math.ceil(pngSize.height / screenSize.scale), screenSize.height);
	});

	it("should be able to open url", async function() {
		hasOneSimulator || this.skip();
		// simply checking thato openurl with https:// launches safari
		await simctl.openUrl("https://www.example.com");
		await new Promise(resolve => setTimeout(resolve, 1000));

		const elements = await simctl.getElementsOnScreen();
		assert.ok(elements.length > 0);

		const addressBar = elements.find(element => element.type === "TextField" && element.name === "TabBarItemTitle" && element.label === "Address");
		assert.ok(addressBar !== undefined, "should have address bar");
	});

	it("should be able to list apps", async function() {
		hasOneSimulator || this.skip();
		const apps = await simctl.listApps();
		const packages = apps.map(app => app.packageName);
		assert.ok(packages.includes("com.apple.mobilesafari"));
		assert.ok(packages.includes("com.apple.reminders"));
		assert.ok(packages.includes("com.apple.Preferences"));
	});

	it("should be able to get elements on screen", async function() {
		hasOneSimulator || this.skip();
		await simctl.pressButton("HOME");
		await new Promise(resolve => setTimeout(resolve, 2000));

		const elements = await simctl.getElementsOnScreen();
		assert.ok(elements.length > 0);

		// must have News app in home screen
		const element = elements.find(e => e.type === "Icon" && e.label === "News");
		assert.ok(element !== undefined, "should have News app in home screen");
	});

	it("should be able to launch and terminate app", async function() {
		hasOneSimulator || this.skip();
		await restartPreferencesApp();
		await new Promise(resolve => setTimeout(resolve, 2000));
		const elements = await simctl.getElementsOnScreen();

		const buttons = elements.filter(e => e.type === "Button").map(e => e.label);
		assert.ok(buttons.includes("General"));
		assert.ok(buttons.includes("Accessibility"));

		// make sure app is terminated
		await simctl.terminateApp("com.apple.Preferences");
		const elements2 = await simctl.getElementsOnScreen();
		const buttons2 = elements2.filter(e => e.type === "Button").map(e => e.label);
		assert.ok(!buttons2.includes("General"));
	});

	it("should throw an error if button is not supported", async function() {
		hasOneSimulator || this.skip();
		try {
			await simctl.pressButton("NOT_A_BUTTON" as any);
			assert.fail("should have thrown an error");
		} catch (error) {
			assert.ok(error instanceof Error);
			assert.ok(error.message.includes("Button \"NOT_A_BUTTON\" is not supported"));
		}
	});
});



================================================
FILE: test/png.ts
================================================
import assert from "node:assert";
import { PNG } from "../src/png";


describe("png", async () => {
	it("should be able to parse png", () => {
		const buffer = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII=";
		const png = new PNG(Buffer.from(buffer, "base64"));
		assert.ok(png.getDimensions().width === 1);
		assert.ok(png.getDimensions().height === 1);
	});

	it("should be able to to detect an invalid png", done => {
		try {
			const buffer = btoa("IAMADUCKIAMADUCKIAMADUCKIAMADUCKIAMADUCK");
			const png = new PNG(Buffer.from(buffer, "base64"));
			png.getDimensions();
			done(new Error("should have thrown an error"));
		} catch (error) {
			done();
		}
	});
});



================================================
FILE: .github/ISSUE_TEMPLATE/bug_report.md
================================================
---
name: Bug report
about: Create a report to help us improve
title: ''
labels: ''
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**Configuration (please complete the following information):**
- Agent: [e.g, Claude Desktop, Cursor]
- OS: [e.g, Mac, Linux, Windows]
- Device used: [e.g. Android, iOS, iOS Simulator]
- Device version: [e.g, 18.3.2]
- Device model: [e.g., Samsung Galaxy S25]

**To Reproduce**
Steps to reproduce the behavior:
1. Use prompt '...'
2. Then do '...'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.



================================================
FILE: .github/workflows/build.yml
================================================
name: Build
permissions:
  contents: write

on:
  push:
    branches:
      - main
    tags:
      - "*.*.*"
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Setup Java
      uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: '17'

    - name: Use Node.js 22
      uses: actions/setup-node@v4
      with:
        node-version: '22'
        cache: 'npm'

    - name: Install dependencies
      run: npm install

    - name: Audit
      run: npm audit --audit-level high

    - name: Lint
      run: npm run lint

    - name: Update version
      if: github.ref_type == 'tag'
      run: |
        npm version "${{ github.ref_name }}" --no-git-tag-version
        npm update

    - name: Build
      run: |
        npm run build

    - name: Publish
      if: github.ref_type == 'tag'
      env:
        NPM_AUTH_TOKEN: ${{ secrets.NPM_AUTH_TOKEN }}
      run: |
        echo "//registry.npmjs.org/:_authToken=$NPM_AUTH_TOKEN" >> ~/.npmrc
        npm publish

#    - name: Install Android SDK
#      uses: android-actions/setup-android@v3
#
#    - name: Create and start Android emulator
#      run: |
#        # create avd
#        echo "y" | sdkmanager "system-images;android-31;google_apis;x86_64"
#        avdmanager create avd -n test -k "system-images;android-31;google_apis;x86_64" --device "pixel"
#        # start emulator
#        sudo ANDROID_AVD_HOME="$HOME/.config/.android/avd" nohup $ANDROID_HOME/emulator/emulator -avd test -no-metrics -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect &
#        # wait for device
#        adb wait-for-device
#        echo "Waiting for sys.boot_completed"
#        while [[ -z $(adb shell getprop dev.bootcomplete) ]]; do sleep 1; done;
#      timeout-minutes: 10
#
#    - name: Run android tests
#      run: |
#        npm test


================================================
FILE: .husky/pre-commit
================================================
npm run lint


