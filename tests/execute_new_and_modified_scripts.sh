#!/bin/bash

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

require_root

latest_main_commit=$(git rev-parse "refs/remotes/origin/main")
current_commit=$(git rev-parse HEAD)

scripts_to_be_tested=$(git diff --no-color --name-only "$latest_main_commit" "$current_commit" | grep --color=never \\.sh$ | grep --color=never ^scripts\\/)

for item in $scripts_to_be_tested
do
    msg_info "Executing $item"
    chmod +x "$item"
    sudo bash "$item"
    if [[ $? -ne 0 ]]; then
        msg_error "Failed executing $item"
        exit 1
    fi
done
