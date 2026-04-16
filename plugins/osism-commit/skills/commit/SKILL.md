---
name: commit
description: Stage and commit changes following OpenStack git commit message guidelines. Use when the user wants to commit code changes.
disable-model-invocation: false
allowed-tools: Bash Read Edit Grep Glob
argument-hint: [optional message hint]
---

# OpenStack-Style Git Commit

Create a git commit following the OpenStack commit message guidelines
(https://wiki.openstack.org/wiki/GitCommitMessages).

User hint: $ARGUMENTS

Committer identity:
- Name: !`git config user.name`
- Email: !`git config user.email`

## Step 1: Understand the changes

Run these in parallel:
- `git status` (never use `-uall`)
- `git diff` and `git diff --cached` to see staged and unstaged changes
- `git log --oneline -10` to see recent commit style

Read changed files as needed to fully understand the change.

## Step 2: Draft the commit message

Follow this structure strictly:

```
<subject line>

<body>

<footer>
```

### Subject line rules

- Maximum 50 characters
- No period at the end
- Mention the affected component if applicable (e.g., "libvirt: ...")
- Use imperative mood ("Add feature" not "Added feature")
- Be specific, not vague ("Fix NPE in volume migration" not "Fix bug")

### Body rules

- Separate from subject with a blank line
- Wrap all lines at 72 characters
- Explain **what** the problem was, **why** the change is needed, and **how**
  the solution works
- The message must contain all information required to fully understand and review the patch
- Mention known limitations or future work if relevant
- "Less is not more. More is more." -- provide comprehensive context
- Do NOT include information only relevant to earlier patch iterations

### Footer rules

Add relevant trailers, each on its own line, in this order:

- `DocImpact` -- if documentation changes are needed
- `APIImpact` -- if public HTTP APIs change (include reasoning)
- `SecurityImpact` -- if security review is warranted
- `UpgradeImpact` -- if there are upgrade implications
- `Closes-Bug: #NNNNNNN` -- if this fully fixes a Launchpad bug
- `Partial-Bug: #NNNNNNN` -- if this partially fixes a bug
- `Related-Bug: #NNNNNNN` -- if merely related to a bug
- `Story: NNNNNNN` / `Task: NNNNN` -- for Storyboard references
- `Implements: blueprint <name>` -- if implementing a blueprint

Only include trailers that are actually relevant. Do not invent bug numbers or references.

**Always include the following trailers (in this exact order, Signed-off-by MUST be last):**

```
AI-assisted: Claude Code
Signed-off-by: <user name> <user email>
```

- `AI-assisted: Claude Code` is an OSISM project convention for commits created with Claude Code.
- `Signed-off-by` is required on every commit. Obtain the name and email from `git config user.name` and `git config user.email`. The `Signed-off-by` line must always be the **very last line** of the commit message, after all other trailers.

## Step 3: Structural check

Before committing, verify:
- There is only **one logical change** per commit (the cardinal rule)
- Whitespace changes are not mixed with functional changes
- Unrelated functional changes are not combined
- If the user's arguments (`$ARGUMENTS`) contain hints, incorporate them

## Step 4: Commit

- Stage relevant files by name (avoid `git add -A` or `git add .`)
- Do NOT stage files that likely contain secrets (.env, credentials, etc.)
- Create the commit using a HEREDOC for the message:

```bash
git commit -m "$(cat <<'EOF'
Subject line here

Body here, wrapped at 72 characters.

Relevant-Trailer: value
AI-assisted: Claude Code
Signed-off-by: Full Name <email@example.com>
EOF
)"
```

- Run `git status` after committing to verify success
- Show the user the final commit message

## Important

- Ask the user before committing if the change seems to bundle multiple logical changes
- If pre-commit hooks fail, fix the issue and create a NEW commit (never amend)
- When amending a commit, the commit message must describe the **full commit** as
  it stands after the amendment, not just the changes made in the amendment. Read
  the existing commit message with `git log -1` and update it to reflect the
  complete change.
- Never push unless explicitly asked
