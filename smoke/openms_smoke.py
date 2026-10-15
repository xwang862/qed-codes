"""OpenMS: QED-RHF (coherent state) for the common case. QED-CCSD is broken in the public tree, so QED-HF only."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

common.workdir("openms")
import numpy as np  # noqa: E402
from pyscf import gto  # noqa: E402
from openms.lib import boson  # noqa: E402
from openms.mqed import qedhf  # noqa: E402

mol = gto.M(atom=[(s, xyz) for s, xyz in common.ATOMS_BOHR], unit="Bohr", basis=common.BASIS, symmetry=False,
            verbose=4, output="openms.log")
res = {}
for label, use_cs in (("cs", True), ("fock", False)):
    qed = boson.Photon(mol, omega=np.array([common.OMEGA]), vec=np.array([common.LAMBDA]), use_cs=use_cs)
    mf = qedhf.RHF(mol, qed=qed)
    mf.conv_tol = 1e-12
    mf.max_cycle = 500
    mf.kernel()
    res[label] = (float(mf.e_tot), bool(mf.converged))
common.write_result(
    "OpenMS", "QED-RHF (coherent state)", res["cs"][0], None, src="OpenMS",
    conventions=dict(gauge="length", reference="coherent-state QED-RHF (use_cs=True); Fock-basis variant in extra",
                     dse="included (add_dse default), 1/2 (lambda.D)^2",
                     coupling="vec = lambda vector (|vec| = lambda, direction normalized); bilinear lambda sqrt(omega/2)",
                     photons="nboson_states = 1 (default)", dipole="D includes the nuclear dipole (add_nuc_dipole=True)"),
    extra=dict(e_qedhf_fock_basis=res["fock"][0], converged=dict(cs=res["cs"][1], fock=res["fock"][1])),
    notes="QED-CCSD module broken in the public tree (missing epcc_equations, cqcpy), so QED-HF only.")
