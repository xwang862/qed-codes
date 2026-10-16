# qed-codes

This repo collects open-source ab initio cavity-QED codes. Each is pinned, reproducible, and built and
smoke-tested. The repo holds the build recipes and environments, not the codes
themselves: every code is a git submodule pinned to one commit.

| code | upstream | env | what it offers (cavity QED) |
|---|---|---|---|
| hilbert | [edeprince3/hilbert](https://github.com/edeprince3/hilbert) | `qed-psi4` | Psi4 plugin: QED-HF/DFT/TDDFT/CIS, QED-CCSD; with TiledArray: QED-CCSD-21/22 and QED-EOM-EE-CCSD-21 |
| cqed-scf | [FoleyLab/cqed-scf](https://github.com/FoleyLab/cqed-scf) | `qed-psi4` | CQED-RHF/RKS/UHF with gradients, QED-CIS, QED-SAPT0 |
| qed-ci | [FoleyLab/qed-ci](https://github.com/FoleyLab/qed-ci) | `qed-psi4` | QED-CIS, QED-CASCI/FCI, SA-QED-CASSCF with gradients |
| psi4polaritonic | [FoleyLab/psi4polaritonic](https://github.com/FoleyLab/psi4polaritonic) | `qed-psi4` | psi4numpy scripts: CQED-RHF, CS-CQED-CIS |
| pdaggerq | [edeprince3/pdaggerq](https://github.com/edeprince3/pdaggerq) | `qed-psi4` | symbolic generator of QED-CC/EOM equations (no numbers) |
| OpenMS | [lanl/OpenMS](https://github.com/lanl/OpenMS) | `qed-pyscf` | PySCF-based QED-HF variants (coherent state, SC, VT, squeezed), QED-FCI, AFQMC |
| eT | [eT-program/eT](https://gitlab.com/eT-program/eT) | `qed-compiled` | QED-HF, SC-QED-HF, TD-QED-HF, QED-CCSD (ground state, EOM, gradients), QED-FCI/CASCI |
| Octopus | [octopus-code/octopus](https://gitlab.com/octopus-code/octopus) | `qed-compiled` | real-space QEDFT (photon OEP/KLI, pxLDA, Casida); no Gaussian-basis QED-HF |
| ExaChem + TAMM | [ExaChem/exachem](https://github.com/ExaChem/exachem), [NWChemEx/TAMM](https://github.com/NWChemEx/TAMM) | `qed-linux` | QED-HF, QED-DFT, QED-CCSD with up to 2 photons (Linux only, MPI) |

`manifest.yaml` is the reference for each code: URL, pinned commit, license, build and test commands, QED
methods, conventions (gauge, coherent state, dipole self-energy, coupling definition, photon truncation),
status and notes. Read it before using a code.

**Licenses.** Several codes are GPL-3.0 (hilbert, cqed-scf, qed-ci, eT, Octopus), and OpenMS uses a custom
LANL notice. Use them as separate programs. Don't copy their code into qedpy (Apache-2.0).

## Layout

```
pixi.toml, pixi.lock     environments (one feature per code) and the solved lock file
manifest.yaml            per-code facts (see above)
.gitmodules, src/        the codes as pinned submodules; src/deps/ holds pinned build-time dependencies
scripts/
  job.py                 resumable step runner: logs/<step>.log + ledger status.json / STATUS.md
  build/<code>.sh        out-of-tree builds (called by pixi tasks build-<code>)
  test/<code>.sh         each package's own shortest test (pixi tasks test-<code>)
  activate/<code>.sh     PYTHONPATH entries, sourced on activation
  fetch_all.sh           plain-git fallback: clone every code at its pin (no pixi needed)
  make_hooks.sh          writes hooks/<env>.sh (pixi shell-hook) for Lmod
  add_submodules.sh      one-time submodule setup (history; not needed after cloning)
smoke/                   common smoke case (common.py) and one <code>_smoke.* per code
results/<code>.json      smoke-test numbers and conventions per code
containers/              Dockerfile and host driver for the Linux (ExaChem) container
modulefiles/qed-code/    example Lmod modulefiles, one per env (not installed anywhere)
patches/                 source patches, if ever needed (none so far)
# generated, not tracked:
.pixi/  build/  install/  hooks/  logs/  status.json  STATUS.md  smoke/work/
```

## Environments

| env | platforms | contents |
|---|---|---|
| `qed-psi4` | osx-arm64, linux-64 | Psi4 1.10.2 (conda-forge), Python 3.11; hilbert, cqed-scf, qed-ci, psi4polaritonic, pdaggerq |
| `qed-pyscf` | osx-arm64, linux-64 | PySCF 2.11.0 (conda-forge), Python 3.12; OpenMS (editable) |
| `qed-compiled` | osx-arm64, linux-64 | compilers, OpenBLAS, FFTW, GSL; eT (+ static libcint), Octopus |
| `qed-linux` | linux-aarch64, linux-64 | gcc 14, MPICH, CMake < 4; ExaChem + TAMM (built in a container on the Mac) |

Pins that the upstream packages don't enforce (recorded in `pixi.toml` and `manifest.yaml`):
* `einsums ==1.1.5`: with 1.1.6, `import psi4` fails for Psi4 1.10.2.
* `numpy <2.4` in `qed-pyscf`: stock PySCF 2.11.0's `lib.einsum` breaks on numpy >= 2.4.
* `libxc-c ==7.0.0`, `cmake <4` (ExaChem's fetched dependencies), `binutils` in `qed-linux`.

## Install

Requirements:
* [pixi](https://pixi.sh) >= 0.82 and git;
* on macOS, Xcode Command Line Tools (for the SDK);
* for ExaChem on a Mac, [Colima](https://github.com/abiosoft/colima) and the docker CLI.

On macOS: `brew install pixi colima docker`.

```bash
git clone --recursive <this repo> ~/Programs/qed-codes
```
```bash
cd ~/Programs/qed-codes
```
If the clone was not recursive, fetch the pinned sources with either of:
```bash
git submodule update --init --recursive
```
```bash
bash scripts/fetch_all.sh
```

Install the environments you need. They are solved from `pixi.lock`, so nothing is re-solved:
```bash
pixi install -e qed-psi4 --frozen
```
```bash
pixi install -e qed-pyscf --frozen
```
```bash
pixi install -e qed-compiled --frozen
```

Build. Each build is out of tree in `build/<code>` (and `install/<code>`); set `JOBS` for the parallelism:
```bash
JOBS=6 pixi run -e qed-psi4 build-hilbert
```
```bash
pixi run -e qed-psi4 build-qed-ci
```
```bash
pixi run -e qed-psi4 build-pdaggerq
```
```bash
pixi run -e qed-compiled build-et
```
```bash
pixi run -e qed-compiled build-octopus
```

Approximate build times on an M-series laptop:
* hilbert: about 10 min, plus about 40 min the first time, for the TiledArray/MADNESS fetch and build;
* Octopus: about 15 min;
* eT: about 5 min;
* the others: about 1 min.

cqed-scf, psi4polaritonic and OpenMS need no build.

**hilbert must be rebuilt whenever `pixi.lock` changes Psi4** (plugin ABI).

### Steps through the ledger (recommended)

`scripts/job.py` runs any command with a per-step log and a ledger, so an interrupted session can resume.
Steps that already passed are skipped unless you pass `--force`.

```bash
python3 scripts/job.py run 10-build-hilbert --est 60 -- pixi run -e qed-psi4 build-hilbert
```
```bash
python3 scripts/job.py show
```

`STATUS.md` lists every step with its state and time, plus log excerpts of failed steps.

### ExaChem (Linux container)

ExaChem builds only on Linux. On the Mac it builds in an arm64 Ubuntu container. The project is mounted
read-only, and the Linux env, package cache and build trees live on named Docker volumes (`qed-codes-*`), never
in the Mac's `.pixi/`.

```bash
colima start --vm-type vz --cpu 6 --memory 12 --disk 100
```
```bash
pixi run exachem-image
```
```bash
JOBS=4 pixi run exachem-build
```
```bash
pixi run exachem-run
```
```bash
pixi run exachem-smoke
```

* `exachem-image` builds a minimal image: Ubuntu pinned by digest, plus pixi.
* `exachem-build` installs `qed-linux`, then builds TAMM and ExaChem (about 1.5 h the first time).
* `exachem-run` runs ExaChem's own QED test and compares it with the reference.
* `exachem-smoke` runs our smoke case and writes `results/exachem.json`.
* Use `EXACHEM_CLEAN=1` to rebuild from scratch, and `bash containers/exachem.sh shell` for a shell.
* `colima stop` frees the VM's memory.

On a linux-64 cluster, skip the container: `pixi install -e qed-linux --frozen`, then
`pixi run -e qed-linux build-exachem-native`. Set `EXACHEM_WORK` for the build location; the default is `/work`.

## Use

Run a command in an environment:
```bash
pixi run -e qed-psi4 python my_script.py
```
Or open a shell:
```bash
pixi shell -e qed-psi4
```

* hilbert: `import hilbert` after `import psi4`. The coupling is `cavity_coupling_strength = lambda / sqrt(2 omega)`.
  See `smoke/hilbert_smoke.py`.
* qed-ci and psi4polaritonic both ship a module named `helper_cqed_rhf.py`, and both are on `PYTHONPATH`.
  Put the one you want first on `sys.path` (see the smoke scripts).
* eT: `python build/eT/build/eT_launch.py input.inp`.
* Octopus: `install/octopus/bin/octopus` (reads `inp` in the current directory).
* ExaChem: `/work/install/exachem/bin/ExaChem input.json` inside the container (`mpirun -n 2`).

## Tests and smoke tests

```bash
pixi run -e qed-psi4 test-hilbert
```
Similarly `test-cqed-scf`, `test-qed-ci`, `test-psi4polaritonic` and `test-pdaggerq` in `qed-psi4`;
`test-openms` in `qed-pyscf`; `test-et` and `test-octopus` in `qed-compiled`; `pixi run exachem-run` for ExaChem.
These run each package's own shortest QED test in `smoke/work/` (nothing is written into `src/`).

Our smoke tests use one common case:
* H2O/STO-3G;
* the Bohr geometry of qedpy's `studies/validation/hilbert/cases.py`;
* lambda = (0, 0, 0.05) a.u. and omega = 0.5 Eh.

They run QED-HF, plus QED-CCSD where available:
```bash
pixi run -e qed-psi4 python smoke/hilbert_smoke.py
```
Results go to `results/<code>.json`, with the fields code, commit, env, method, basis, lambda, omega, e_hf,
e_tot, conventions and notes. Octopus and pdaggerq run their own QED examples instead.

## Cluster use (Lmod)

On the cluster:
1. Clone recursively.
2. Install the envs and build.
3. Run `pixi run hooks`. This writes `hooks/<env>.sh` with absolute paths, so regenerate it after every
   install or update.
4. Copy `modulefiles/qed-code/<env>.lua` into a `MODULEPATH` directory.
5. Set `QED_CODES_ROOT` if the clone is not at `~/Programs/qed-codes`.

The modules belong to the family `qed-code`, so only one can be loaded at a time.

## Rules for changes

* Don't modify submodule sources. A build that needs a patch gets one as
  `patches/<code>-<topic>.patch`, applied in its build script, after discussion.
* Changing a pin: check out the new commit in `src/<code>`, `git add src/<code>`, then update `manifest.yaml`
  and rebuild.
* Changing an environment: edit `pixi.toml`, run `pixi lock`, then commit both files. Rebuild hilbert if Psi4
  changed, and run `pixi run hooks`.
* Commit after each coherent step. The repo is meant to be moved with `git clone --recursive`.
