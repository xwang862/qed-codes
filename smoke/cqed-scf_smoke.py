"""cqed-scf: CQED-RHF for the common case (H2O/STO-3G, lambda = (0, 0, 0.05), omega = 0.5). QED-HF only."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

common.workdir("cqed-scf")
import numpy as np  # noqa: E402
import psi4  # noqa: E402
from cqed_scf import CQEDCalculator, CQEDConfig  # noqa: E402

psi4.core.set_output_file("output.dat", False)
config = CQEDConfig(lambda_vector=np.array(common.LAMBDA), omega=common.OMEGA, reference="rhf",
                    psi4_options={"basis": common.BASIS, "scf_type": "pk", "e_convergence": 1e-12,
                                  "d_convergence": 1e-10},
                    density_fitting=False, charge=0, multiplicity=1, dispersion_policy="none", debug=False)
e = CQEDCalculator(config=config).energy(common.psi4_geometry())
common.write_result(
    "cqed-scf", "CQED-RHF", float(e), None,
    conventions=dict(gauge="length", reference="coherent-state QED-RHF", dse="included (exact JK backend)",
                     coupling="lambda vector in a.u.", photons="mean field only"),
    notes="QED-HF only (exact integrals, dispersion off). QED-CIS/QED-SAPT0 also available, not run here.")
