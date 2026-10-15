"""eT 2.6.1: QED-HF and QED-CCSD (1 boson state) for the common case (H2O/STO-3G, lambda = 0.05 along z, omega = 0.5)."""
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

w = common.workdir("eT")
inp = """- system
   charge: 0
- method
   qed-hf
   qed-ccsd
- memory
   available: 4
- solver cholesky
   threshold: 1.0d-12
- solver scf
   algorithm:          scf-diis
   energy threshold:   1.0d-11
   residual threshold: 1.0d-11
- solver cc gs
   residual threshold: 1.0d-10
   energy threshold:   1.0d-11
- do
   ground state
- boson
   modes:          1
   boson states:   {1}
   frequency:      {%.10f}
   coupling:       {%.10f}
   polarization:   {%.10f, %.10f, %.10f}
- geometry
units: bohr
basis: %s
%s
""" % (common.OMEGA, (sum(x * x for x in common.LAMBDA)) ** 0.5,
       *[x / (sum(y * y for y in common.LAMBDA)) ** 0.5 for x in common.LAMBDA],
       common.BASIS, "\n".join(common.xyz_lines()))
open("h2o_qed.inp", "w").write(inp)
launcher = os.path.join(common.ROOT, "build", "eT", "build", "eT_launch.py")
subprocess.run([sys.executable, launcher, "h2o_qed.inp", "--omp", "1"], check=True)
out = open("h2o_qed.out").read()


def last(pattern):
    m = re.findall(pattern, out)
    return float(m[-1]) if m else None


e_hf = last(r"Total energy:\s+(-?\d+\.\d+)")
e_cc = last(r"Final ground state energy \(a\.u\.\):\s+(-?\d+\.\d+)")
common.write_result(
    "eT", "QED-HF + QED-CCSD (boson states 1)", e_hf, e_cc,
    conventions=dict(gauge="length", reference="coherent-state QED-HF",
                     dse="included, 1/2 (lambda.(d - <d>))^2 (no quadrupole oei override)",
                     coupling="coupling = |lambda| a.u., polarization unit vector; bilinear g = lambda sqrt(omega/2) (d.e)",
                     photons="boson states {1}: QED-CCSD with T1,T2 plus S0 b+, S1 b+, S2 b+ (QED-CCSD-1 type)"),
    extra=dict(output=os.path.join(w, "h2o_qed.out")),
    notes="Energies parsed from h2o_qed.out ('Total energy' of QED-HF, 'Final ground state energy' of QED-CCSD).")
