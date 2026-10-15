#!/bin/bash
# Host-side driver for the linux-aarch64 ExaChem container (pixi tasks exachem-image / exachem-build / exachem-run).
#   image : build the image (Dockerfile.exachem: pinned ubuntu digest + pixi)
#   build : pixi install -e qed-linux --frozen, then TAMM + ExaChem (scripts/build/exachem.sh)
#   run   : ExaChem's own QED test (scripts/test/exachem.sh)
#   smoke : our common smoke case (smoke/exachem_smoke.py; writes results/exachem.json)
#   shell : interactive shell with the same mounts
# The project is bind-mounted read-only at /qed-codes (except results/ and smoke/work/, read-write); envs, package cache, build trees and outputs live on
# named volumes (qed-codes-pixi-envs, qed-codes-rattler, qed-codes-work). Logs go to stdout (captured by job.py).
# --shm-size=4g: GlobalArrays (MPI-3 shared memory) aborts with the default 64 MB /dev/shm.
set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd)
IMG=qed-codes/exachem:ubuntu24.04-pixi0.82.0
MOUNTS=(-v qed-codes-pixi-envs:/pixi-envs -v qed-codes-rattler:/root/.cache/rattler -v qed-codes-work:/work
        -v "$R":/qed-codes:ro -v "$R/results":/qed-codes/results -v "$R/smoke/work":/qed-codes/smoke/work)
RUN=(docker run --rm --shm-size=4g "${MOUNTS[@]}" -e JOBS="${JOBS:-4}" -e EXACHEM_CLEAN="${EXACHEM_CLEAN:-0}" -e PIXI_NO_TELEMETRY=1)
case "${1:-}" in
  image) docker build -t "$IMG" -f "$R/containers/Dockerfile.exachem" "$R/containers" ;;
  build) "${RUN[@]}" "$IMG" bash -c "pixi install -e qed-linux --frozen && pixi run --frozen -e qed-linux build-exachem-native" ;;
  run)   "${RUN[@]}" "$IMG" bash -c "pixi run --frozen -e qed-linux test-exachem-native" ;;
  smoke) "${RUN[@]}" "$IMG" bash -c "pixi run --frozen -e qed-linux python smoke/exachem_smoke.py" ;;
  shell) docker run --rm -it --shm-size=4g "${MOUNTS[@]}" "$IMG" bash ;;
  *) echo "usage: $0 image|build|run|shell"; exit 2 ;;
esac
