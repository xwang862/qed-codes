"""Common smoke-test case and result writer for the external cavity-QED codes (stdlib only).

Case: H2O / STO-3G, geometry in Bohr copied from the workspace's
qedpy/studies/validation/hilbert/cases.py (MOLECULES["H2O"], Angstrom values times A2B there),
cavity lambda = (0, 0, 0.05) a.u., omega = 0.5 Eh, closed shell, no frozen core.

Each smoke/<code>_smoke.* writes results/<code>.json with:
  code, commit, env, method, basis, lambda, omega, e_hf, e_tot, extra, conventions, notes, date
e_hf is the QED-HF (cavity mean-field) total energy, e_tot the highest-level correlated total energy the
code offers for this case (null if none). Values are recorded as printed by each code; no comparison here.
"""

import json
import os
import subprocess
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A2B = 1.0 / 0.52917721092
ATOMS_BOHR = [("O", (0.0, 0.0, -0.065655108083 * A2B)),
              ("H", (0.0, -0.757365949175 * A2B, 0.520997104927 * A2B)),
              ("H", (0.0, 0.757365949175 * A2B, 0.520997104927 * A2B))]
BASIS = "sto-3g"
LAMBDA = (0.0, 0.0, 0.05)
OMEGA = 0.5


def xyz_lines(fmt="%-2s %20.12f %20.12f %20.12f"):
    return [fmt % (s, *xyz) for s, xyz in ATOMS_BOHR]


def psi4_geometry():
    """Psi4 molecule string in Bohr, no reorientation / COM shift, C1."""
    return "0 1\n" + "\n".join(xyz_lines()) + "\nunits bohr\nno_reorient\nno_com\nsymmetry c1\n"


def commit(code):
    try:
        return subprocess.check_output(["git", "-C", os.path.join(ROOT, "src", code), "rev-parse", "HEAD"],
                                       text=True).strip()
    except Exception:
        return None


def write_result(code, method, e_hf, e_tot=None, conventions=None, notes="", extra=None, src=None):
    out = dict(code=code, commit=commit(src or code), env=os.path.basename(os.environ.get("CONDA_PREFIX", "")),
               method=method, basis=BASIS, geometry_bohr=ATOMS_BOHR, **{"lambda": list(LAMBDA)}, omega=OMEGA,
               e_hf=e_hf, e_tot=e_tot, extra=extra or {}, conventions=conventions or {}, notes=notes,
               date=time.strftime("%Y-%m-%d %H:%M:%S"))
    os.makedirs(os.path.join(ROOT, "results"), exist_ok=True)
    path = os.path.join(ROOT, "results", code + ".json")
    json.dump(out, open(path, "w"), indent=1)
    print("wrote %s: e_hf %s  e_tot %s" % (path, e_hf, e_tot), flush=True)
    return out


def workdir(code):
    """Fresh scratch directory smoke/work/<code> (git-ignored); chdir into it."""
    d = os.path.join(ROOT, "smoke", "work", code)
    os.makedirs(d, exist_ok=True)
    os.chdir(d)
    return d
