# promptcraft

A Claude Code plugin marketplace for sharing skills, hooks, and configuration
across the OSISM team.

## Installation

```bash
# Register the marketplace (one-time)
claude plugin marketplace add osism/promptcraft

# Install plugins
claude plugin install osism-commit@promptcraft
claude plugin install osism-changelog@promptcraft
```

## Plugins

### osism-commit

OpenStack-style git commits with OSISM conventions.

**Provides:**

- `/commit` skill — stages and commits following OpenStack commit message
  guidelines with OSISM-required trailers (`AI-assisted`, `Signed-off-by`)
- Co-Authored-By blocker hook — prevents Claude Code's system prompt from
  injecting `Co-Authored-By:` trailers that violate OSISM policy

**After installing**, remove these if you have them:

- `~/.claude/skills/commit/` (replaced by the plugin)
- Any inline Co-Authored-By hook in `~/.claude/settings.json` (replaced by the
  plugin)

### osism-changelog

Generate and update `CHANGELOG.md` from git history, following OSISM changelog
conventions.

**Provides:**

- `/osism-changelog` skill — analyses the commits between release tags and
  writes [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)-style entries
  (`Added` / `Changed` / `Fixed` / `Removed` / `Dependencies`) with clickable
  GitHub PR references, then inserts them into `CHANGELOG.md`

It is the in-session equivalent of `osism/release`'s
`generate-changelog-input.sh` — no headless batching, Claude does the analysis
directly. Run it from within the target repository.

**Usage:**

```text
/osism-changelog                 # latest v0.* tag
/osism-changelog v0.20260319.0   # a specific tag
/osism-changelog --auto          # every tag newer than the last documented one
/osism-changelog --from <tag>    # every tag from <tag> onwards
/osism-changelog --dry-run       # show the entry without writing CHANGELOG.md
```

## Local Development and Testing

To test changes before pushing, register a local checkout as a separate
marketplace:

```bash
claude plugin marketplace add /path/to/your/promptcraft
```

This registers it as `promptcraft` pointing at your local directory. To keep
both a local and remote marketplace, remove and re-add with different sources
as needed, or register the local checkout first and switch to GitHub later:

```bash
# Switch from local to GitHub
claude plugin marketplace remove promptcraft
claude plugin marketplace add osism/promptcraft
```

## Adding a Plugin

1. Create `plugins/<name>/.claude-plugin/plugin.json`
2. Add skills in `plugins/<name>/skills/` and/or hooks in `plugins/<name>/hooks/`
3. Register in `.claude-plugin/marketplace.json`
