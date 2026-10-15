# pixi activation (feature hilbert): prepend build/hilbert/pkg to PYTHONPATH -- hilbert/{__init__.py,pymodule.py,hilbert.so} (build tree).
# One script per feature because pixi keeps only one value when several features set the same activation.env key.
export PYTHONPATH="$PIXI_PROJECT_ROOT/build/hilbert/pkg${PYTHONPATH:+:$PYTHONPATH}"
