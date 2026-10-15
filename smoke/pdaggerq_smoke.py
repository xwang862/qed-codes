"""pdaggerq: no numerical QED-HF/QED-CCSD (symbolic generator). Smoke = the package's own QED example
examples/qed_ccsd_21.py (QED-CCSD-21 energy and residual equations, spin blocked); record term counts."""
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

common.workdir("pdaggerq")
ex = os.path.join(common.ROOT, "build", "pdaggerq", "src", "examples", "qed_ccsd_21.py")
out = subprocess.run([sys.executable, ex], check=True, capture_output=True, text=True).stdout
open("qed_ccsd_21.out", "w").write(out)
counts, name = {}, None
for line in out.splitlines():
    m = re.match(r"Equation (\S+):", line)
    if m:
        name = m.group(1)
        counts[name] = 0
    elif name and line.startswith("['"):
        counts[name] += 1
common.write_result(
    "pdaggerq", "symbolic QED-CCSD-21 equations (examples/qed_ccsd_21.py)", None, None,
    conventions=dict(gauge="length (operators w0, d+, d- = bilinear coupling, f, v)",
                     reference="coherent-state style: 'd-' is the dipole fluctuation term",
                     photons="QED-CCSD-21: t0_1p, t1_1p, t2_1p one-photon amplitudes"),
    extra=dict(terms_per_equation=counts, output="smoke/work/pdaggerq/qed_ccsd_21.out"),
    notes="No numbers: pdaggerq derives equations only (no Gaussian-basis QED-HF).")
