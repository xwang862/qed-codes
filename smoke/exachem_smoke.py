"""ExaChem v0.1.0 (inside the container, qed-linux env): QED-HF and QED-CCSD for the common case
(H2O/STO-3G, Bohr geometry, lambda = 0.05 along z, omega = 0.5), mpirun -n 2."""
import glob
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

common.workdir("exachem")
inp = {
    "geometry": {"coordinates": ["%s %.12f %.12f %.12f" % (s, *xyz) for s, xyz in common.ATOMS_BOHR], "units": "bohr"},
    "basis": {"basisset": common.BASIS},
    "common": {"maxiter": 200},
    "SCF": {"charge": 0, "multiplicity": 1, "scf_type": "restricted", "conve": 1e-10, "convd": 1e-9,
            "tol_int": 1e-20, "tol_lindep": 1e-6, "diis_hist": 10,
            "qed_omegas": [common.OMEGA], "qed_volumes": [], "qed_lambdas": [0.05], "qed_polvecs": [[0.0, 0.0, 1.0]]},
    "CD": {"diagtol": 1e-12},
    "CC": {"threshold": 1e-10, "ccsd_maxiter": 200, "ndiis": 5},
    "TASK": {"scf": False, "ccsd": True},
}
json.dump(inp, open("h2o_qed_sto3g.json", "w"), indent=1)
exe = os.path.join(os.environ.get("EXACHEM_WORK", "/work"), "install", "exachem", "bin", "ExaChem")
with open("exachem.out", "w") as fh:
    subprocess.run(["mpirun", "-n", "2", exe, "h2o_qed_sto3g.json"], check=True, stdout=fh, stderr=subprocess.STDOUT,
                   env=dict(os.environ, OMP_NUM_THREADS="1"))
outs = [f for f in glob.glob("**/*.json", recursive=True) if f != "h2o_qed_sto3g.json"]
res = None
for f in sorted(outs, key=os.path.getmtime):
    d = json.load(open(f))
    if "output" in d and "SCF" in d["output"]:
        res = d["output"]
scf, cc = res["SCF"], res.get("CCSD", {})
common.write_result(
    "exachem", "QED-HF + QED-CCSD (closed-shell CD, up to 2 photons)", float(scf["final_energy"]),
    float(cc["final_energy"]["total"]) if cc else None,
    conventions=dict(gauge="length", reference="coherent-state QED-HF (nuclear coherent-state shift)",
                     dse="dipole and quadrupole DSE one- and two-body terms (scf_qed.cpp)",
                     coupling="qed_lambdas (a.u.), qed_polvecs unit vector, qed_omegas (Eh)",
                     photons="QED-CCSD amplitudes t0..t2 with 1p and 2p (two-photon) blocks"),
    extra=dict(energy_qed=scf.get("energy_qed"), energy_qed_et=scf.get("energy_qed_et"),
               ccsd_correlation=cc.get("final_energy", {}).get("correlation") if cc else None, mpi_ranks=2),
    notes="Run in the linux-aarch64 container; numbers from ExaChem's output JSON.")
