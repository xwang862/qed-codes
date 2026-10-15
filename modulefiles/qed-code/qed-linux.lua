-- Example Lmod modulefile for the qed-codes pixi environment qed-linux (not installed anywhere yet).
-- On the cluster: clone qed-codes (git clone --recursive), pixi install -e qed-linux, pixi run hooks,
-- then copy this file to <MODULEPATH>/qed-code/qed-linux.lua and set QED_CODES_ROOT if the clone is elsewhere.
-- One qed-code module at a time (family), since all of them set PATH/CONDA_PREFIX/PYTHONPATH.
family("qed-code")
whatis("Name: qed-code/qed-linux")
whatis("Description: external cavity-QED codes: ExaChem/TAMM v0.1.0 (Linux only)")
help([[pixi environment qed-linux of ~/Programs/qed-codes; see manifest.yaml there.]])
local root = os.getenv("QED_CODES_ROOT") or pathJoin(os.getenv("HOME"), "Programs/qed-codes")
local hook = pathJoin(root, "hooks/qed-linux.sh")
if not isFile(hook) then
  LmodError("missing " .. hook .. " -- run 'pixi run hooks' in " .. root)
end
setenv("QED_CODES_ROOT", root)
source_sh("bash", hook)
