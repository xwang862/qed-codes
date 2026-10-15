# pixi activation (feature psi4polaritonic): prepend src/psi4polaritonic to PYTHONPATH -- scripts only, no build.
# One script per feature because pixi keeps only one value when several features set the same activation.env key.
export PYTHONPATH="$PIXI_PROJECT_ROOT/src/psi4polaritonic${PYTHONPATH:+:$PYTHONPATH}"
