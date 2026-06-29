---
name: osism-changelog
description: Generate or update CHANGELOG.md from git history following OSISM changelog conventions. Use when the user wants to create or update a changelog entry for a release/tag.
disable-model-invocation: false
allowed-tools: Bash Read Edit Write Grep Glob
argument-hint: "[tag] | --auto | --from <tag> | --dry-run"
---

# OSISM Changelog Generator

Generate or update `CHANGELOG.md` for the repository in the current working
directory by analysing the git history between release tags. This is the native
equivalent of `osism/release`'s `generate-changelog-input.sh` — you analyse the
commits yourself instead of shelling out to a headless `claude -p`.

Arguments: $ARGUMENTS

OSISM repositories use CalVer tags of the form `v0.YYYYMMDD.N` (e.g.
`v0.20260319.0`). The changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and entries link pull requests back to GitHub.

## Step 1: Determine the mode

Parse `$ARGUMENTS` into exactly one mode. Default behaviour writes the result
into `CHANGELOG.md`; `--dry-run` may be combined with any mode to print the
entry without modifying any file.

- *(no tag / no flag)* — generate an entry for the **latest** `v0.*` tag.
- `<tag>` — generate an entry for that specific tag. If `<tag>` does **not**
  exist yet but its date component equals today's date, treat it as **release
  preparation**: use `HEAD` as the range end (the tag will be created later).
- `--from <tag>` — process **every** tag from `<tag>` onward (oldest → newest).
- `--auto` — read the first `## [v…]` heading in `CHANGELOG.md` (the most
  recent documented release) and process every tag after it.
- `--dry-run` — do everything except writing `CHANGELOG.md`; print the entry
  instead.

Reject `--auto` combined with `--from` or an explicit tag — the same way the
reference script does — and tell the user why.

## Step 2: Detect the GitHub repository

PR references must be clickable on GitHub, so resolve `org/repo` from the remote:

```bash
git remote get-url origin | sed -E 's#.*github\.com[:/]([^/]+/[^/.]+)(\.git)?$#\1#'
```

If no remote is found, warn the user and ask whether to continue with an
`org/repo` they supply (otherwise PR links cannot be formed).

## Step 3: Resolve the tags and their commit ranges

Work from the ordered list of release tags:

```bash
git tag --sort=version:refname | grep '^v0\.'
```

For each target tag determine its **previous** tag and **date**:

- **Previous tag** = the tag immediately before the target in that list. If the
  target is the very first tag, use the repository's root commit as the base:
  `git rev-list --max-parents=0 HEAD | tail -1`.
- **Virtual "today" tag** — if there are commits after the last real tag
  (`git rev-list --count <last-tag>..HEAD` > 0), add a synthetic tag
  `v0.<YYYYMMDD>.0` (today's date) covering `<last-tag>..HEAD`. Skip this if the
  last real tag already equals that name.
- **Release preparation** — if a requested tag does not exist but its date is
  today, the range end is `HEAD` instead of the tag.
- **Date** — extract `YYYY-MM-DD` from the tag name by matching
  `v[0-9]+\.([0-9]{4})([0-9]{2})([0-9]{2})\.[0-9]+`. For a not-yet-created tag,
  use today's date.

Announce the resolved tag(s), their date(s), previous tag(s) and commit counts
before generating anything.

## Step 4: Collect the commits

For each range, list commits oldest-first and read message + diff:

```bash
git log --reverse --format='%h' <previous>..<ref>     # <ref> is the tag or HEAD
git log -1 --format='%an%n%ci%n%s%n%b' <commit>        # author, date, subject, body
git show --format='' <commit>                          # the diff
```

Skip **pure merge commits**. For a very large range, read the commits in
successive chunks (e.g. a few dozen at a time via narrower `git log` ranges)
rather than dumping everything at once — this is the native equivalent of the
script's batching, with no temp files.

## Step 5: Write the changelog entry

For each tag, produce a single entry. **Follow this format exactly:**

```markdown
## [<tag>] - <YYYY-MM-DD>

### Added
- New features (org/repo#123)

### Changed
- Changes to existing features (org/repo#456)

### Fixed
- Bug fixes (org/repo#789)

### Removed
- Removed features (org/repo#101)

### Dependencies
- package-name 1.0.0 → 1.1.0 (org/repo#102)
```

Rules:

- Keep the sections in this order: **Added, Changed, Fixed, Removed,
  Dependencies**. **Omit** any section that would be empty.
- Group related commits into one bullet; write one bullet per logical change.
- Write entries in **English**, concise and understandable.
- Start each entry with a **capital letter**; do **not** end with a period.
- Ignore pure merge commits.
- Dependency / Renovate updates go in **Dependencies**, formatted as
  `package-name old_version → new_version` — lowercase package name, real `→`
  arrow (U+2192).
- If a commit subject contains a PR reference like `(#123)`, append it to the
  bullet as `(org/repo#123)` so it becomes a clickable GitHub link. Do not
  invent PR numbers.
- The entry header is `## [<tag>] - <YYYY-MM-DD>`. For multiple tags, emit one
  entry each, newest last (they will be inserted so the newest ends up on top).

## Step 6: Insert into CHANGELOG.md

Skip this step entirely for `--dry-run` (print the entry instead).

Read `CHANGELOG.md` and choose the matching branch:

- **Missing or empty file** — create it with the standard header, then the
  entry. Header template (fill `<Month DD, YYYY>` from today's date):

  ```markdown
  # Changelog

  All notable changes to this project will be documented in this file.

  The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
  and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

  This file was started on <Month DD, YYYY>. Changes prior to this date are not included in the CHANGELOG.
  ```

- **Has existing `## [v…]` entries** — insert the new entry **immediately
  before the first** one (newest on top), separated by a blank line.
- **Header only, no version entries** — append the entry at the end.

When processing multiple tags (`--from` / `--auto`), insert them so the newest
release ends up at the top of the file.

## Step 7: Report

- Show the user the entry/entries you produced.
- State exactly what changed in `CHANGELOG.md` (created / inserted before
  `<tag>` / appended), or that nothing was written for `--dry-run`.
- Do **not** `git add`, commit, or push — leave that to the user or the
  `/commit` skill.

## Important

- Only consider `v0.*` tags, matching OSISM's CalVer scheme and the reference
  script. The date parser also tolerates a `vN.` prefix for release preparation.
- Never fabricate PR numbers, versions, or changes — every bullet must trace
  back to a real commit in the range.
- If a range contains no user-facing changes (only merges/noise), say so rather
  than inventing entries.
