#!/bin/bash
set -euo pipefail

echo "==> Running syntax checks (bash -n)"
shopt -s globstar
files=(lib/**/*.sh *.sh tools/**/*.sh)
for f in "${files[@]}"; do
  for file in $f; do
    if [[ -f "$file" ]]; then
      echo "- checking $file"
      bash -n "$file"
    fi
  done
done

echo "==> Running rollback example in dry-run mode"
# Ensure we run example in dryrun so it won't change system
./rollback_example_eg1.sh --yes --dryrun

echo "==> CI checks passed"
