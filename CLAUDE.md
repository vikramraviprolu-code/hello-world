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
