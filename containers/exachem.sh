#!/bin/bash
# Host-side driver for the linux-aarch64 ExaChem container (pixi tasks exachem-image / exachem-build / exachem-run).
#   image : build the image (Dockerfile.exachem: pinned ubuntu digest + pixi)
#   build : pixi install -e qed-linux --frozen, then TAMM + ExaChem (scripts/build/exachem.sh)
#   run   : ExaChem's own QED test and our smoke input (scripts/test/exachem.sh)
#   shell : interactive shell with the same mounts
# The project is bind-mounted read-only at /qed-codes; envs, package cache, build trees and outputs live on
# named volumes (qed-codes-pixi-envs, qed-codes-rattler, qed-codes-work). Logs go to stdout (captured by job.py).
set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd)
IMG=qed-codes/exachem:ubuntu24.04-pixi0.82.0
MOUNTS=(-v qed-codes-pixi-envs:/pixi-envs -v qed-codes-rattler:/root/.cache/rattler -v qed-codes-work:/work
        -v "$R":/qed-codes:ro)
RUN=(docker run --rm "${MOUNTS[@]}" -e JOBS="${JOBS:-4}" -e EXACHEM_CLEAN="${EXACHEM_CLEAN:-0}" -e PIXI_NO_TELEMETRY=1)
case "${1:-}" in
  image) docker build -t "$IMG" -f "$R/containers/Dockerfile.exachem" "$R/containers" ;;
  build) "${RUN[@]}" "$IMG" bash -c "pixi install -e qed-linux --frozen && pixi run --frozen -e qed-linux build-exachem-native" ;;
  run)   "${RUN[@]}" "$IMG" bash -c "pixi run --frozen -e qed-linux test-exachem-native" ;;
  shell) docker run --rm -it "${MOUNTS[@]}" "$IMG" bash ;;
  *) echo "usage: $0 image|build|run|shell"; exit 2 ;;
esac
