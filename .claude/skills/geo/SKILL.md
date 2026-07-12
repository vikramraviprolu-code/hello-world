---
name: geo
description: >-
  Optimize product-site content for AI citations (GEO — Generative Engine
  Optimization): make pages quotable and extractable for ChatGPT, Perplexity,
  Google AI Overviews, Gemini, and Claude, and generate/validate llms.txt
  files. Use when the user wants a product page, docs page, or site optimized
  for AI answer engines, asks why AI tools don't cite their product, wants an
  llms.txt created or checked, or says "GEO", "AI citations", or "AI search
  visibility".
---

# GEO — make product sites citable by AI engines

Answer engines don't rank pages; they **extract answers**. A page gets cited
when it contains a standalone, factual, attributable block that directly
answers the query the engine is synthesizing. This skill optimizes product
sites for that, and implements the llms.txt standard (llmstxt.org).

## Workflow

### 1. Collect inputs

Ask for (or locate in the repo): the page content/URL, the product's
one-line definition, and the **target AI queries** — the 5–15 questions a
prospect would ask an AI engine ("what is X", "X vs Y", "best tool for Z",
"X pricing"). Every optimization is judged against these queries; if the
user can't list them, derive candidates from the page and confirm.

### 2. Audit the page

Score each target query: does the page contain a block an engine could lift
verbatim to answer it? Check against `reference/geo-techniques.md`:
definitions, quotable claims, factual density, freshness signals, Q&A
structure, entity consistency, schema. Report a per-query PASS/PARTIAL/MISS
table before changing anything.

### 3. Rewrite

Apply the techniques in `reference/geo-techniques.md`. Non-negotiables:
- One **25–50 word standalone definition** of the product near the top.
- Every target query answered in a **self-contained block** (a heading in
  question form + a direct first-sentence answer).
- Claims carry **numbers, dates, and sources**; no unverifiable superlatives.
- The product name + descriptor phrased **identically** across pages
  (entities are matched by string consistency).
- End with the anti-slop pass: strip AI-tell phrasing ("in today's
  fast-paced world", "unlock", "seamless", "game-changer", rule-of-three
  padding). Cited text is quoted text — it must read like a human expert.

### 4. Ship the llms.txt

Generate `/llms.txt` (and optionally `.md` page variants) per
`reference/llms-txt.md` — exact format rules and a product-site template.
Validate before shipping:

```bash
.claude/skills/geo/scripts/llms_txt_check.py path/to/llms.txt
```

### 5. Report honestly

Output: changes made, per-query coverage after, and next steps. Label every
metric **Measured**, **User-provided**, or **Estimated** — never present an
estimate as measured. Critical honesty rule: these changes improve
**citability** (testable in minutes: paste the URL + target query into a
live-fetch engine and see if it quotes you). **Unprompted surfacing** —
being cited without the URL supplied — is gated by each engine's crawl and
index cycles: expect weeks, confounded by competitors. Never promise fast
surfacing.

## Scope boundaries

- Human conversion (hero anatomy, persuasion, CTA design) is the
  `landing-pages` skill's job — invoke it in the same pass so a product page
  serves both AI engines and the humans who land on it.
- Structural/technical SEO (Core Web Vitals, redirects, canonical tags) is
  out of scope — recommend a dedicated SEO pass instead.
- Writing net-new marketing copy from nothing is normal writing, not GEO —
  this skill optimizes toward target queries.
- Never fabricate testimonials, statistics, or sources to look "authoritative";
  if a claim lacks a source, flag it to the user instead.
