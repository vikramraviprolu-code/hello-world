# llms.txt — the standard, distilled (source: llmstxt.org, verified 2026-07)

`/llms.txt` is a markdown file at the site root giving LLMs a curated,
context-window-sized map of the site at **inference time** (when a user asks
an engine about you — exactly the GEO moment). Complement, not replacement,
for sitemap.xml (too big, no external links) and robots.txt (access control,
not content).

## Exact format (order matters; parseable by regex/parsers)

1. **H1 with the site/product name** — the only required element.
2. A **blockquote** with a short summary carrying the key facts needed to
   interpret the rest (this is where your 25–50 word product definition
   goes).
3. Zero or more markdown blocks (paragraphs, lists — **no headings**) with
   details, caveats, and how to read the linked files.
4. Zero or more **H2 sections containing file lists**: each entry is
   `- [name](url)` optionally followed by `: notes`.
5. An H2 section literally named **`## Optional`** has special meaning:
   its links may be skipped when a shorter context is needed. Put
   secondary material there.

## Companion convention: .md page variants

Serve a clean markdown twin of every important page at the same URL with
`.md` appended (`/pricing.html.md`; bare directory URLs get
`index.html.md`). Engines and agents fetch these instead of parsing your
HTML/JS. If the site is static-generated this is usually a build step
(plugins exist for VitePress, Docusaurus, Drupal; nbdev does it natively).

## Product-site template

```markdown
# Acme

> Acme is an open-source feature-flag service for JavaScript and Python
> teams. Local evaluation under 1 ms, hosted control plane, self-hostable
> under MIT license. Free tier up to 5 seats; paid from $12/seat/month.

Key facts:

- Founded 2024; SOC 2 Type II since 2025.
- SDKs: JS/TS, Python, Go. REST + streaming APIs.
- Not a full A/B-testing analytics suite — pairs with your analytics tool.

## Product

- [What is Acme](https://acme.dev/product.md): capabilities and architecture
- [Pricing](https://acme.dev/pricing.md): tiers, limits, self-hosting terms
- [Acme vs LaunchDarkly](https://acme.dev/compare/launchdarkly.md): honest comparison table

## Docs

- [Quick start](https://acme.dev/docs/quickstart.md): first flag in 5 minutes
- [API reference](https://acme.dev/docs/api.md): REST + streaming endpoints, auth, rate limits

## Optional

- [Changelog](https://acme.dev/changelog.md): release history, most recent first
- [Blog](https://acme.dev/blog/index.html.md): engineering posts and benchmarks
```

## Authoring guidelines (from the spec)

- Concise, unambiguous language; no unexplained jargon.
- Every link gets a brief informative description — engines choose what to
  fetch based on those notes.
- Test it: expand the file (fetch all linked URLs into one context) and ask
  a model questions about the product; iterate until it answers correctly.
- Keep it curated — it's a briefing, not a sitemap dump.

## Validation

Run `scripts/llms_txt_check.py <file>` — enforces the section order, H1
presence, blockquote position, link-list syntax, and flags common mistakes
(H3 headings, prose inside file-list sections, bare URLs).
