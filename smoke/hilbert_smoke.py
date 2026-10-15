"""hilbert: QED-RHF and QED-CCSD-21 (TiledArray) for the common case (H2O/STO-3G, lambda = (0, 0, 0.05), omega = 0.5).
Options follow the workspace's studies/validation/hilbert/run_hilbert.py (Cholesky 1e-12, relaxed QED-HF orbitals)."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

common.workdir("hilbert")
import psi4  # noqa: E402
import hilbert  # noqa: E402,F401

psi4.core.set_output_file("output.dat", False)
psi4.set_memory("2000 MB")
psi4.geometry(common.psi4_geometry())
psi4.set_options({"basis": common.BASIS, "scf_type": "cd", "cholesky_tolerance": 1e-12,
                  "e_convergence": 1e-10, "d_convergence": 1e-10, "r_convergence": 1e-8})
g = [x / math.sqrt(2.0 * common.OMEGA) for x in common.LAMBDA]
psi4.set_options({"hilbert__" + k: v for k, v in {
    "cavity_frequency": common.OMEGA, "cavity_coupling_strength": g, "qed_use_relaxed_orbitals": True,
    "mad_num_threads": 1, "tile_size": -1}.items()})
e_cc = psi4.energy("qed-ccsd-21")
e_hf = psi4.variable("SCF TOTAL ENERGY")
common.write_result(
    "hilbert", "QED-RHF + QED-CCSD-21 (TiledArray)", float(e_hf), float(e_cc),
    conventions=dict(gauge="length", reference="coherent-state QED-RHF (USE_COHERENT_STATE_BASIS default true), relaxed orbitals",
                     dse="included (hilbert default one-electron DSE treatment)",
                     coupling="cavity_coupling_strength g = lambda / sqrt(2 omega) (vector), cavity_frequency = omega",
                     photons="QED-CCSD-21: T1, T2 with one-photon S0, S1, S2 (i.e. QED-CCSD-1)"),
    extra=dict(e_rhf=float(psi4.variable("HF TOTAL ENERGY")) if psi4.core.has_variable("HF TOTAL ENERGY") else None,
               g=g, scf_type="cd 1e-12"),
    notes="Same option set as studies/validation/hilbert/run_hilbert.py (ground state only here).")
