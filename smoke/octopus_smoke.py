"""Octopus 16.4: no Gaussian-basis QED-HF, so the smoke test is the package's own QEDFT example
testsuite/functionals/21-qedft-breit-3d.01-pxlda-hydrogen.inp (3D H atom, photon-free pxLDA,
one photon mode omega = 0.374501, lambda = 0.5 along x), run unchanged; numbers vs the testsuite's .test values."""
import os
import re
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

w = common.workdir("octopus")
for d in ("static", "exec", "restart"):
    shutil.rmtree(d, ignore_errors=True)
src = os.path.join(common.ROOT, "src", "octopus", "testsuite", "functionals", "21-qedft-breit-3d.01-pxlda-hydrogen.inp")
shutil.copy(src, "inp")
exe = os.path.join(common.ROOT, "install", "octopus", "bin", "octopus")
env = dict(os.environ, OCT_PARSE_ENV="1", OMP_NUM_THREADS="1")
with open("octopus.out", "w") as fh:
    subprocess.run([exe], check=True, stdout=fh, stderr=subprocess.STDOUT, env=env)
info = open(os.path.join("static", "info")).read()


def field(label, idx):
    for line in info.splitlines():
        if line.strip().startswith(label):
            return float(line.split()[idx - 1])
    return None


vals = dict(total=field("Total       =", 3), eigenvalues=field("Eigenvalues =", 3), photon_ex=field("Photon ex.", 4))
ref = dict(total=-0.44049659, eigenvalues=-0.62350605, photon_ex=0.04482205)   # 21-qedft-breit-3d.test
common.write_result(
    "octopus", "QEDFT pxLDA (package example 21-qedft-breit-3d.01-pxlda-hydrogen, H atom)", None, vals["total"],
    conventions=dict(gauge="length (dipole), photon-free QEDFT", reference="Kohn-Sham with photon exchange pxLDA (no Hartree for 1 e-)",
                     coupling="%PhotonModes: omega | lambda | polarization (a.u.)", photons="photon-free functional (no explicit photon states)"),
    extra=dict(values=vals, testsuite_reference=ref, system="H atom, Radius 10, Spacing 0.5, omega 0.374501, lambda 0.5 x"),
    notes="Not the common H2O case: Octopus is real-space QEDFT without Gaussian-basis QED-HF. e_tot = Kohn-Sham total energy.")
