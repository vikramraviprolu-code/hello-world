# GEO techniques for product sites

How answer engines pick what to cite: they retrieve candidate pages, chunk
them, and select chunks that (a) directly answer the synthesized query,
(b) stand alone without surrounding context, and (c) carry trust signals
(specificity, sources, dates, named authors). Optimize the chunk, not just
the page.

## 1. Standalone definition block

One 25–50 word definition of the product, near the top, that survives being
lifted out of the page:

> **Bad:** "Acme takes your workflow to the next level with seamless
> integrations."
> **Good:** "Acme is an open-source feature-flag service for JavaScript and
> Python teams. It evaluates flags locally in under 1 ms, syncs via a hosted
> control plane, and is self-hostable under an MIT license."

Test: paste the block alone into a chat — can a model answer "what is Acme?"
correctly from it? Ship only if yes.

## 2. Answer blocks per target query

For each target query, a section whose heading is the question (or close
paraphrase) and whose **first sentence is the answer**:

```markdown
## How much does Acme cost?

Acme is free for up to 5 seats; paid plans start at $12/seat/month
(billed annually) as of January 2026. Self-hosting is free and unlimited.
```

Details follow the first sentence, never precede it. Comparison queries
("Acme vs LaunchDarkly") get an honest table — engines love tables, and an
honest one gets cited where a puff piece doesn't.

## 3. Factual density and sourcing

- Replace adjectives with numbers: "fast" → "p99 flag evaluation of 0.8 ms
  (benchmark, Jan 2026)".
- Date every perishable claim ("as of", changelog links).
- Attribute external claims to named sources with links.
- Named humans (author bylines, engineer quotes) beat anonymous copy.
- Never invent any of the above; missing data is the user's to supply.

## 4. Entity consistency

Engines resolve products as entities via string-level consistency. Pick ONE
canonical form — "Acme — open-source feature flags" — and use it verbatim
across the site: title tags, H1s, footer, docs, GitHub README, LinkedIn.
Inconsistent descriptors fragment the entity and dilute citations.

## 5. Structure engines can parse

- Q&A sections, tables, and lists over long prose.
- FAQ/Product/Organization schema (JSON-LD) that **mirrors visible
  content** — schema saying what the page doesn't show is a trust risk.
- Clean headings hierarchy; one topic per section.
- llms.txt + optional `.md` page variants (see `llms-txt.md`).

## 6. Per-engine notes (heuristics, not guarantees)

| Engine | Leans toward |
|---|---|
| Google AI Overviews | Pages already ranking top-10; schema markup; direct answer in first sentences |
| Perplexity | Freshness; densely factual pages; docs and comparison tables |
| ChatGPT (browse) | Bing-indexed pages; clear titles matching the query phrasing |
| Claude / Gemini | Clean structure and unambiguous definitions; llms.txt helps agentic fetching |

Common denominator: the standalone, sourced, dated answer block. Optimize
for that first; engine-specific tuning is marginal.

## 7. Anti-slop pass (always last)

Cited text is quoted text. Strip before shipping:
- Filler openers: "In today's fast-paced/digital world…"
- Marketing verbs with no referent: unlock, empower, supercharge, elevate.
- "seamless", "cutting-edge", "game-changer", "robust" (unless quantified).
- Rule-of-three padding and mirrored sentence rhythm.
- Every sentence must add a fact, or it goes.

## Distribution surfaces beyond your own site

Engines and coding agents also pull from indexed third-party surfaces:

- **Context7** (context7.com) — indexes library/product docs and injects
  them into AI coding agents (Cursor, Claude Code) at inference time. If
  the product has developer docs or an API, submit them ("Adding
  Libraries" on their site) — free distribution into the exact context
  where developers ask about your problem space.
- GitHub README (often the entity's strongest-crawled page), Medium,
  Reddit, YouTube transcripts. Keep the canonical entity phrasing
  identical on all of them.

## Measuring

- **Citability (minutes):** give a live-fetch engine the URL and the target
  query; check whether the answer quotes/cites the page. Re-test after
  changes. This is a proxy, but a fast one.
- **Surfacing (weeks):** the same query WITHOUT the URL. Gated by crawl and
  index refresh; don't attribute week-1 silence to bad content.
- Track per-query: date, engine, cited? (Y/N), rank among sources. A plain
  markdown table in the repo beats a dashboard at this scale.
