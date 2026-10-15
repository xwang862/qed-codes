"""qed-ci: CQED-RHF and QED-FCI (coherent-state basis, 1 photon) for the common case."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

common.workdir("qed-ci")
# put qed-ci first: psi4polaritonic ships a module of the same name (helper_cqed_rhf)
sys.path.insert(0, os.path.join(common.ROOT, "build", "qed-ci", "src"))
import numpy as np  # noqa: E402
import psi4  # noqa: E402
import helper_cqed_rhf  # noqa: E402
from helper_PFCI import PFHamiltonianGenerator  # noqa: E402

assert "qed-ci" in helper_cqed_rhf.__file__, helper_cqed_rhf.__file__
psi4.core.set_output_file("output.dat", False)
opts = {"basis": common.BASIS, "scf_type": "pk", "e_convergence": 1e-12, "d_convergence": 1e-10}
hf = helper_cqed_rhf.cqed_rhf(np.array(common.LAMBDA), common.psi4_geometry(), dict(opts))
cavity = {"omega_value": common.OMEGA, "lambda_vector": np.array(common.LAMBDA), "ci_level": "fci",
          "davidson_roots": 2, "number_of_photons": 1, "photon_number_basis": False,
          "coherent_state_basis": True, "canonical_mos": True, "rdm_root": 0}
pf = PFHamiltonianGenerator(common.psi4_geometry(), dict(opts), cavity)
e_fci = float(np.real(pf.CIeigs[0]))
common.write_result(
    "qed-ci", "CQED-RHF + QED-FCI (1 photon, coherent-state basis)", float(hf["CQED-RHF ENERGY"]), e_fci,
    conventions=dict(gauge="length", reference="coherent-state QED-RHF", dse="included",
                     coupling="lambda vector in a.u.; omega enters the photon term of the CI",
                     photons="number_of_photons = 1 (photon states 0, 1) in the coherent-state basis"),
    extra=dict(e_rhf=float(hf["RHF ENERGY"]), cqed_reference_energy=float(getattr(pf, "cqed_reference_energy", float("nan"))),
               ci_roots=[float(np.real(x)) for x in pf.CIeigs[:2]]),
    notes="No QED-CCSD in qed-ci; e_tot is QED-FCI (full CI in all 7 orbitals x photon 0/1).")
