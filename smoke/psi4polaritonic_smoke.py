"""psi4polaritonic: CQED-RHF for the common case (H2O/STO-3G, lambda = (0, 0, 0.05), omega = 0.5). QED-HF only."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

common.workdir("psi4polaritonic")
# put psi4polaritonic first: qed-ci ships a module of the same name (helper_cqed_rhf)
sys.path.insert(0, os.path.join(common.ROOT, "src", "psi4polaritonic"))
import numpy as np  # noqa: E402
import psi4  # noqa: E402
import helper_cqed_rhf  # noqa: E402

assert "psi4polaritonic" in helper_cqed_rhf.__file__, helper_cqed_rhf.__file__
psi4.core.set_output_file("output.dat", False)
opts = {"basis": common.BASIS, "scf_type": "pk", "e_convergence": 1e-12, "d_convergence": 1e-10}
res = helper_cqed_rhf.cqed_rhf(np.array(common.LAMBDA), common.psi4_geometry(), opts)
common.write_result(
    "psi4polaritonic", "CQED-RHF", float(res["CQED-RHF ENERGY"]), None,
    conventions=dict(gauge="length", reference="coherent-state QED-RHF (photon in vacuum after the coherent shift)",
                     dse="included: 1/2 (lambda.(d - <d>))^2 with the quadrupole one-electron term",
                     coupling="lambda vector in a.u.; omega does not enter the mean-field energy",
                     photons="none beyond the coherent state (mean field)"),
    extra=dict(e_rhf=float(res["RHF ENERGY"])),
    notes="QED-HF only; omega is not an input of cqed_rhf (the coherent-state mean-field energy is omega-independent).")
