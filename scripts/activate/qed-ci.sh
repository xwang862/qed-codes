# pixi activation (feature qed-ci): prepend build/qed-ci/src to PYTHONPATH -- built copy of src/qed-ci (cfunctions.so).
# One script per feature because pixi keeps only one value when several features set the same activation.env key.
export PYTHONPATH="$PIXI_PROJECT_ROOT/build/qed-ci/src${PYTHONPATH:+:$PYTHONPATH}"
