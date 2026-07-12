# Project notes

This repo is Vikram's personal Claude Code skill collection. Skills live in
`.claude/skills/`; install user-wide on a Mac with
`bash .claude/skills/install-all.sh` (yodha-memory's capture runtime needs
its own `setup/install.sh`, macOS only).

## Skill discovery resources (for future use)

- **Awesome Claude Skills** (primary directory):
  https://github.com/ComposioHQ/awesome-claude-skills — ~200 curated
  community skills. Search it via the `skills-directory` skill
  (`.claude/skills/skills-directory/scripts/catalog.sh search <term>`).
- **skills.sh** — https://www.skills.sh — skill listing site (pages often
  block direct fetch; go to the underlying GitHub repo instead).
- **Anthropic official skills**: https://github.com/anthropics/skills —
  authoritative source for skill-creator, docx/pdf/pptx/xlsx, etc.
- **obra/superpowers**: https://github.com/obra/superpowers — well-regarded
  workflow skills (TDD, worktrees, etc.).

## Julian Shapiro handbooks (product-site copy / growth)

https://www.julian.com — free long-form handbooks: Landing Pages guide,
Writing Well, Growth Marketing, Startup guide
(https://www.julian.com/guide/startup/intro). Relevant as the
human-conversion complement to the `geo` skill (AI citability). BLOCKED
from the cloud sandbox (proxy 403, archive.org also blocked) — fetch it
in a local Mac session or have the user paste content. The `landing-pages`
skill was built from training-knowledge frameworks (attributed, never
verbatim) as a first pass; TRUE IT UP against the real guide text once
content is available.

## Context7 (up-to-date library docs)

https://context7.com — injects current, version-specific library docs into
coding agents; fixes stale-training-data hallucinations. Install on each
Mac with `npx ctx7 setup --claude` (installs their official skill; free API
key via their dashboard). Unreachable from the cloud sandbox (proxy blocks
it), so don't attempt to call it there. GEO note: submitting product docs
to Context7 is a free AI-citation distribution channel (see
`.claude/skills/geo/reference/geo-techniques.md`).

## Auto-trigger rules

- When editing or reviewing product-site content (marketing pages, docs,
  llms.txt), use the `geo` skill (AI citability) and the `landing-pages`
  skill (human conversion) together, without being asked.
- When creating or modifying a skill in this repo, follow `skill-creator`
  and validate with its `quick_validate.py`.
- When implementing features or bugfixes with tests, follow the
  `test-driven-development` skill.
- When asked "is there a skill for X", search via `skills-directory`.

## House rules for adding skills

- Vet before install: read the full SKILL.md and every script; check
  licenses; no phone-home defaults; prefer lean standalone skills over
  bundles (distill what we need instead — see `geo` vs the 120-skill
  marketing bundle).
- Validate with
  `python3 .claude/skills/skill-creator/scripts/quick_validate.py <dir>`.
- Commit with source repo + license attribution.
- Sandbox note: GitHub API/clone is blocked for foreign repos here, but
  `raw.githubusercontent.com` and `registry.npmjs.org` work.
