# Catalog of covered AI tools

Source: https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools (branch `main`)

Each entry below is a top-level folder in the source repo. Pass the exact
folder name (quoted, spaces preserved) to `scripts/fetch_prompt.sh` to pull
its files.

| Folder name | Product / category |
|---|---|
| `Amp` | Amp (Sourcegraph) coding agent |
| `Anthropic` | Anthropic / Claude-related prompts |
| `Augment Code` | Augment Code assistant |
| `Cluely` | Cluely |
| `CodeBuddy Prompts` | CodeBuddy |
| `Comet Assistant` | Comet (Perplexity) browser assistant |
| `Cursor Prompts` | Cursor editor agent |
| `Devin AI` | Devin autonomous engineer |
| `Emergent` | Emergent |
| `Google` | Google AI tooling prompts |
| `Junie` | Junie (JetBrains) |
| `Kiro` | Kiro (AWS) |
| `Leap.new` | Leap.new |
| `Lovable` | Lovable app builder |
| `Manus Agent Tools & Prompt` | Manus agent |
| `NotionAi` | Notion AI |
| `Open Source prompts` | Assorted open-source agent prompts |
| `Orchids.app` | Orchids.app |
| `Perplexity` | Perplexity answer engine |
| `Poke` | Poke |
| `Qoder` | Qoder |
| `Replit` | Replit Agent |
| `Same.dev` | Same.dev |
| `Trae` | Trae (ByteDance) |
| `Traycer AI` | Traycer AI |
| `VSCode Agent` | VS Code Copilot agent |
| `Warp.dev` | Warp terminal AI |
| `Windsurf` | Windsurf (Codeium) Cascade agent |
| `Xcode` | Xcode AI |
| `Z.ai Code` | Z.ai Code |
| `dia` | Dia browser |
| `v0 Prompts and Tools` | Vercel v0 |

`Open Source prompts` is itself a folder of subfolders (multiple projects).
Folder names and contents change upstream; if a fetch returns nothing, run the
script with `--root` to re-list the current top-level folders:

```bash
.claude/skills/system-prompts/scripts/fetch_prompt.sh --root
```
