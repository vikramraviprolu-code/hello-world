---
name: shadcn
description: >-
  Add and manage shadcn/ui components in a React project via the shadcn CLI —
  initialize a project, discover components (search/list/view), add them with
  dependencies, apply design presets, and check for updates. Use when the user
  wants to add a UI component (button, dialog, data-table, etc.), set up
  shadcn/ui, restyle with a preset, or work with a components.json registry.
  Requires Node.js/npx and a frontend project.
---

# shadcn/ui — component management via the CLI

shadcn/ui isn't an installed dependency you import — it copies component
source into the project so it's yours to edit. The `shadcn` CLI
(package `shadcn`, invoked `npx shadcn@latest <cmd>`) is the real tool; this
skill drives it correctly. Verified against CLI v4.13.0 (MIT).

Alternative: shadcn ships a native MCP server — `npx shadcn@latest mcp`, or
register it in the agent config. If that MCP is connected in this session,
prefer its tools; otherwise use the CLI as below. Same backend either way.

## Step 0 — project + init check

The CLI writes files into the current project (components under the path in
`components.json`, plus Tailwind/CSS-var edits). Before anything:

```bash
node --version && npx --version        # Node/npx required
ls components.json 2>/dev/null          # already initialized?
```

- No `components.json` → run `npx shadcn@latest init` first. It installs
  deps, adds the `cn` util, and configures Tailwind + CSS variables. Confirm
  the target project with the user before initializing — this edits config.
- Always work on a clean git state so the user can review the diff the CLI
  produces.

## Core workflow: discover → inspect → add

```bash
# Discover
npx shadcn@latest list                  # items in the configured registry
npx shadcn@latest search <query>        # search the registry
npx shadcn@latest add                   # interactive: lists all components

# Inspect before installing
npx shadcn@latest view <component>      # show a component's files/details

# Add (installs the component's source + required deps)
npx shadcn@latest add <component>       # e.g. add button / add data-table
npx shadcn@latest add button dialog card   # multiple at once
```

After adding, tell the user which files were created/modified (typically
under `components/ui/`) so they can review and commit.

## Other commands (verified v4.13.0)

- `init` — initialize deps, `cn`, Tailwind, CSS vars (creates components.json)
- `create` — scaffold a new project (opens a browser to pick framework/design)
- `apply --preset <id>` — apply a design preset: overwrites preset config,
  reinstalls detected UI components, updates fonts + CSS vars. Destructive to
  current theming — confirm with the user first.
- `diff` — check installed components for upstream updates
- `migrate` — run project migrations
- `info` — print project/environment info (useful for debugging setup)
- `registry` / `build` — manage/build custom component registries (authoring)
- `mcp` — run shadcn's MCP server

Full CLI docs: https://ui.shadcn.com/docs/cli

## Rules

- Pin invocations with `@latest` (or the project's pinned version) so behavior
  is predictable.
- `add` and `apply` **write into the user's repo** — never run them without
  confirming the project, and surface the resulting diff for review.
- Don't fabricate component names; use `search`/`list`/`add` (no args) to get
  the real registry list before claiming a component exists.
- Since components are copied in and owned by the project, prefer editing the
  local files over re-adding, unless the user wants to reset to upstream.
