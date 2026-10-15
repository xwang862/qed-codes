# Sourced by scripts/test/*.sh: fresh work dir smoke/work/test-<name> (git-ignored) so that nothing is
# written into src/ (Psi4 writes output.dat/timer.dat into the cwd; Python would write __pycache__).
set -euo pipefail
R=${PIXI_PROJECT_ROOT:?run through pixi}
W=$R/smoke/work/test-$1
rm -rf "$W"; mkdir -p "$W"; cd "$W"
export PYTHONDONTWRITEBYTECODE=1 OMP_NUM_THREADS=${OMP_NUM_THREADS:-1} PYTHONUNBUFFERED=1
echo "== test $1 in $W ($(date))"
