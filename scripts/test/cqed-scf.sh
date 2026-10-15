#!/bin/bash
# cqed-scf's own quick tests (lambda = 0 regression and Cartesian projection).
source "$(dirname "$0")/_common.sh" cqed-scf
python -m pytest -p no:cacheprovider -q --rootdir "$W" \
  "$R/src/cqed-scf/tests/test_lambda_zero_regression.py" "$R/src/cqed-scf/tests/test_cartesian_projection.py"
