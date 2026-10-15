#!/bin/bash
# Plain-git fallback (no pixi needed): clone every code into src/<name> at the commit pinned in this repository
# (the submodule gitlinks, i.e. the commits recorded in manifest.yaml), nested submodules included.
# Use it on machines where `git clone --recursive` was not used. Safe to rerun: existing clones are just
# fetched and checked out again.
#   bash scripts/fetch_all.sh            # all codes
#   bash scripts/fetch_all.sh eT octopus # selected codes (path names under src/)
set -euo pipefail
cd "$(dirname "$0")/.."
want=("$@")
git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | while read -r key path; do
  name=${path#src/}
  if [ ${#want[@]} -gt 0 ] && [[ ! " ${want[*]} " =~ " ${name} " ]]; then continue; fi
  url=$(git config -f .gitmodules --get "${key%.path}.url")
  pin=$(git ls-tree HEAD "$path" | awk '{print $3}')     # commit recorded by the superproject
  echo "== $name: $url @ $pin"
  if [ ! -e "$path/.git" ]; then
    rm -rf "$path"; git clone --quiet "$url" "$path"
  fi
  git -C "$path" fetch --quiet --tags origin || true
  git -C "$path" -c advice.detachedHead=false checkout --quiet "$pin"
  git -C "$path" submodule update --init --recursive --quiet
  echo "   at $(git -C "$path" rev-parse HEAD)"
done
