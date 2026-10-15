# pixi activation (feature cqed-scf): prepend src/cqed-scf/src to PYTHONPATH (package cqed_scf).
# Not an editable pypi dependency: the repo tracks src/cqed_scf.egg-info, which an editable install rewrites.
export PYTHONPATH="$PIXI_PROJECT_ROOT/src/cqed-scf/src${PYTHONPATH:+:$PYTHONPATH}"
