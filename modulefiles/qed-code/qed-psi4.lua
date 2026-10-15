-- Example Lmod modulefile for the qed-codes pixi environment qed-psi4 (not installed anywhere yet).
-- On the cluster: clone qed-codes (git clone --recursive), pixi install -e qed-psi4, pixi run hooks,
-- then copy this file to <MODULEPATH>/qed-code/qed-psi4.lua and set QED_CODES_ROOT if the clone is elsewhere.
-- One qed-code module at a time (family), since all of them set PATH/CONDA_PREFIX/PYTHONPATH.
family("qed-code")
whatis("Name: qed-code/qed-psi4")
whatis("Description: external cavity-QED codes: hilbert, cqed-scf, qed-ci, psi4polaritonic, pdaggerq (Psi4 1.10.2)")
help([[pixi environment qed-psi4 of ~/Programs/qed-codes; see manifest.yaml there.]])
local root = os.getenv("QED_CODES_ROOT") or pathJoin(os.getenv("HOME"), "Programs/qed-codes")
local hook = pathJoin(root, "hooks/qed-psi4.sh")
if not isFile(hook) then
  LmodError("missing " .. hook .. " -- run 'pixi run hooks' in " .. root)
end
setenv("QED_CODES_ROOT", root)
source_sh("bash", hook)
