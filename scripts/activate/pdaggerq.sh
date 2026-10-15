# pixi activation (feature pdaggerq): prepend build/pdaggerq/src to PYTHONPATH -- built copy of src/pdaggerq (pdaggerq/_pdaggerq*.so).
# One script per feature because pixi keeps only one value when several features set the same activation.env key.
export PYTHONPATH="$PIXI_PROJECT_ROOT/build/pdaggerq/src${PYTHONPATH:+:$PYTHONPATH}"
