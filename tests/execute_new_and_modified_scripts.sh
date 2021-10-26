#!/bin/bash

latest_main_commit=$(git rev-parse refs/remotes/origin/HEAD)
current_commit=$(git rev-parse HEAD)

scripts_to_be_tested=$(git diff --no-color --name-only "$latest_main_commit" "$current_commit" | grep --color=never \\.sh$ | grep --color=never ^scripts\\/)

for item in $scripts_to_be_tested
do
    echo "Executing $item"
    chmod +x "$item"
    bash "$item"
done