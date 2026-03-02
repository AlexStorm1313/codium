#!/bin/bash

if [ -f "$SSH_AGENT" ]; then
    source "$SSH_AGENT"
    # Verify agent is running
    if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        ssh-agent -s > "$SSH_AGENT"
        source "$SSH_AGENT"
    fi
else
    ssh-agent -s > "$SSH_AGENT"
    source "$SSH_AGENT"
fi
for key in "$HOME/.ssh/id_"*; do
    [ -f "$key" ] || continue
    if ! ssh-add -l | grep -q "$(ssh-keygen -lf "$key" | awk '{print $2}')"; then
        ssh-add "$key" 2>/dev/null || true
    fi
done