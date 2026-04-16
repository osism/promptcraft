#!/usr/bin/env bash
# Block git commit commands that contain Co-Authored-By trailer.

command -v jq >/dev/null 2>&1 || {
    echo "warning: jq not found, skipping co-authored-by policy check" >&2
    exit 0
}

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if echo "$command" | grep -qi '^co-authored-by:'; then
    cat <<'EOF'
{"decision":"block","reason":"STOP: Do not use Co-Authored-By in commit messages. OSISM commit policy requires:\n    AI-assisted: Claude Code\n    Signed-off-by: <your name> <your email>\nUse the /commit skill for the correct format."}
EOF
fi
