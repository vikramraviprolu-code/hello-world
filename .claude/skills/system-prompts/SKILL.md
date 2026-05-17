---
name: system-prompts
description: >-
  Reference catalog of real-world system prompts, agent instructions, and tool
  schemas from production AI tools (Cursor, Devin, v0, Lovable, Windsurf,
  Claude Code, Replit, Perplexity, and ~30 more), sourced from the
  x1xhlol/system-prompts-and-models-of-ai-tools repository. Use when designing,
  reviewing, or reverse-engineering a system prompt or agent for an AI tool;
  when the user asks how a specific AI product prompts its model or structures
  its tools; or when comparing prompting patterns across products.
---

# System Prompts of AI Tools

A working reference to the system prompts, agent instructions, and internal
tool definitions of production AI products, mirrored from
[x1xhlol/system-prompts-and-models-of-ai-tools](https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools).

## When to use this skill

- Designing a new system prompt or agent and you want proven patterns to draw
  from.
- Reviewing or critiquing an existing prompt against how shipped products do it.
- The user asks "how does <tool> prompt its model?" or "what tools does
  <tool> expose?".
- Comparing approaches across products (e.g. how Cursor vs. Windsurf vs. Claude
  Code structure file-editing tools, or how agents are told to plan).

## How to use it

1. Identify which products are relevant. The full list of covered tools and
   their folder paths is in `reference/catalog.md`. Read it first if you're
   unsure what's available.
2. Fetch the actual prompt(s) on demand with the helper script — the source
   repo is large, so nothing is bundled here; content is pulled live:

   ```bash
   .claude/skills/system-prompts/scripts/fetch_prompt.sh "Cursor Prompts"
   ```

   This downloads every file under that tool's folder into
   `.claude/skills/system-prompts/.cache/<tool>/` and prints the saved paths.
   Pass `--list` to only enumerate files without downloading:

   ```bash
   .claude/skills/system-prompts/scripts/fetch_prompt.sh --list "Devin AI"
   ```

3. Read the fetched files with the Read tool and apply what's relevant. Always
   cite which product a pattern came from when presenting it to the user.

## What to look for when mining these prompts

These recur across nearly every shipped agent and are worth extracting
deliberately:

- **Role + capability framing**: the opening identity statement and an explicit
  enumeration of what the agent can and cannot do.
- **Tool-use discipline**: rules for when to call tools vs. answer directly,
  parallelizing independent calls, and never naming tools to the user.
- **Editing protocol**: how file edits are represented (diff/patch formats,
  "never print the whole file", read-before-edit invariants).
- **Planning & autonomy**: when to plan first, when to ask vs. proceed, and how
  much to do per turn.
- **Communication style**: terseness rules, markdown constraints, and
  citation/footnote formats (notably Perplexity).
- **Safety & refusal**: scoped refusal language and guardrails phrased to
  minimize over-refusal.

## Caveats

- These are community-extracted prompts; treat them as informative, not
  authoritative or current. Products iterate constantly.
- Content is fetched live from GitHub `main`; it changes upstream over time.
- This is for studying prompt design. Do not present another product's prompt
  as your own or copy it verbatim into a competing product.
