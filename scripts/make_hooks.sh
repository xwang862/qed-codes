#!/bin/bash
# Write hooks/<env>.sh = `pixi shell-hook -e <env> --frozen` for every qed-* environment installed on this
# machine (hooks hold absolute paths, so regenerate them on each machine, after every install or update).
# They are sourced by the Lmod modulefiles in modulefiles/qed-code/ (source_sh). Run: pixi run hooks
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p hooks
envdir=.pixi/envs
for env in qed-psi4 qed-pyscf qed-compiled qed-linux; do
  if [ -d "$envdir/$env/conda-meta" ]; then
    # clean environment: otherwise the generating shell's whole PATH (and any active env) is baked into the hook
    env -i HOME="$HOME" USER="${USER:-}" PATH="$(dirname "$(command -v pixi)"):/usr/bin:/bin:/usr/sbin:/sbin" \
      pixi shell-hook -e "$env" --frozen > "hooks/$env.sh.tmp" && mv "hooks/$env.sh.tmp" "hooks/$env.sh"
    echo "hooks/$env.sh ($(wc -l < hooks/$env.sh) lines)"
  else
    echo "skip $env (not installed on this machine)"
  fi
done
