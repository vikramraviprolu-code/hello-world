#!/usr/bin/env python3
"""Validate an llms.txt file against the llmstxt.org spec.

Usage: llms_txt_check.py <path-to-llms.txt>
Exit 0 = valid (warnings allowed), 1 = errors, 2 = usage.

Spec (llmstxt.org): H1 title (required) -> optional blockquote summary ->
optional non-heading detail blocks -> zero or more H2 "file list" sections
of `- [name](url)` entries (optional `: notes`); an H2 named "Optional"
marks skippable links.
"""
import re
import sys

LINK_RE = re.compile(r"^- \[([^\]]+)\]\((\S+?)\)(: .+)?$")
BARE_URL_RE = re.compile(r"^- (https?://\S+)")


def check(path):
    errors, warnings = [], []
    try:
        with open(path, encoding="utf-8-sig") as f:  # utf-8-sig eats a BOM
            lines = f.read().splitlines()
    except OSError as e:
        return [f"cannot read {path}: {e}"], []

    nonblank = [(i + 1, l) for i, l in enumerate(lines) if l.strip()]
    if not nonblank:
        return ["file is empty"], []

    # 1. H1 first.
    ln, first = nonblank[0]
    if not first.startswith("# "):
        errors.append(f"line {ln}: first content must be an H1 title "
                      f"('# Site Name'), found: {first[:50]!r}")

    # 2. Blockquote, if present, must appear before any H2.
    first_h2 = next((ln for ln, l in nonblank if l.startswith("## ")), None)
    first_quote = next((ln for ln, l in nonblank if l.startswith(">")), None)
    if first_quote is None:
        warnings.append("no blockquote summary after the H1 — strongly "
                        "recommended (it's where the product definition goes)")
    elif first_h2 and first_quote > first_h2:
        errors.append(f"line {first_quote}: blockquote summary must come "
                      f"before the first H2 section")

    h1s = [ln for ln, l in nonblank if re.match(r"^# ", l)]
    if len(h1s) > 1:
        errors.append(f"multiple H1s at lines {h1s} — spec allows exactly one")

    in_list_section = False
    section = None
    seen_optional = False
    for ln, l in nonblank:
        if l.startswith("### "):
            errors.append(f"line {ln}: H3+ headings are not part of the spec "
                          f"(only one H1 and H2 section headers)")
        elif l.startswith("## "):
            section = l[3:].strip()
            in_list_section = True
            if section.lower() == "optional":
                seen_optional = True
        elif in_list_section and l.startswith("- "):
            if BARE_URL_RE.match(l):
                errors.append(f"line {ln}: bare URL in file list — use "
                              f"'- [name](url): notes'")
            elif not LINK_RE.match(l):
                errors.append(f"line {ln}: file-list entry doesn't match "
                              f"'- [name](url)' or '- [name](url): notes': "
                              f"{l[:60]!r}")
            elif not LINK_RE.match(l).group(3):
                warnings.append(f"line {ln}: link has no ': description' — "
                                f"engines pick links by their notes")
        elif in_list_section and not l.startswith(("#", "-", ">")):
            warnings.append(f"line {ln}: prose inside H2 section "
                            f"{section!r} — spec expects H2 sections to be "
                            f"link lists only")

    if first_h2 is None:
        warnings.append("no H2 link sections — valid but thin; add curated "
                        "links to .md pages")
    if seen_optional and nonblank[-1][1].startswith("## "):
        warnings.append("'## Optional' section is empty")

    return errors, warnings


def main():
    if len(sys.argv) != 2:
        print(__doc__.strip(), file=sys.stderr)
        sys.exit(2)
    errors, warnings = check(sys.argv[1])
    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    if errors:
        print(f"\n{sys.argv[1]}: INVALID — {len(errors)} error(s), "
              f"{len(warnings)} warning(s)")
        sys.exit(1)
    print(f"{sys.argv[1]}: OK — spec-compliant "
          f"({len(warnings)} warning(s))")


if __name__ == "__main__":
    main()
