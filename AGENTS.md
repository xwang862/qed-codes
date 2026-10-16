# AGENTS.md

Instructions for AI coding agents (Codex, Claude Code, Cursor, Copilot, ...) working in this repository.
Humans should start with `README.md`; this file is the operational version of it.

## What this repo is

A reproducible collection of open-source ab initio cavity-QED codes: hilbert, cqed-scf, qed-ci,
psi4polaritonic, pdaggerq, OpenMS, eT, Octopus and ExaChem/TAMM.
* The codes are **git submodules pinned to exact commits** in `src/`.
* The repo owns only the recipes: `pixi.toml`/`pixi.lock` (environments), `scripts/` (build, test and run
  helpers), `smoke/` (a common test case), `containers/` (Linux container for ExaChem) and `manifest.yaml`.
* `manifest.yaml` is the source of truth for each code: URL, pin, license, build and test commands, QED
  methods, conventions and status. Read it before working on a code.

The typical user request is "install everything" or "install code X and check it works". Some users only want
answers about the codes. Treat those as read-only.

## Ground rules

1. **Never modify anything under `src/`.** These are third-party sources at pinned commits.
   * Builds are out of tree (`build/<code>`, `install/<code>`).
   * Codes that write into their own tree (qed-ci, pdaggerq, eT) are rsync-copied to `build/` first.
   * If a build truly needs a source change, stop and ask the user. An approved patch goes in
     `patches/<code>-<topic>.patch` and is applied by the build script to the copy, never to `src/`.
2. **Don't change pins or environments on your own.**
   * Install with `pixi install -e <env> --frozen`.
   * Run `pixi lock` only when the user asks for an environment change; then commit `pixi.toml` and
     `pixi.lock` together.
   * A Psi4 change requires rebuilding hilbert, which is a plugin tied to the Psi4 ABI.
3. **Ask before large downloads or system changes**: installing pixi, Colima/Docker or Xcode tools, pulling
   images, or creating the Colima VM. A full install downloads about 6–7 GB and uses about 20 GB of disk.
   State sizes when asking. Never use `sudo`.
4. **Licenses.** Most codes are GPL-3.0, and OpenMS uses a custom LANL notice.
   * Do not copy code from `src/` into other projects or into files tracked by this repo.
   * Calling the programs is fine.
5. **Log every long job and make it resumable.**
   * Run builds and tests through `scripts/job.py`, which writes `logs/<step>.log` line by line and the ledger
     `status.json` / `STATUS.md`.
   * Estimate the time first and tell the user.
   * On restart, read `STATUS.md` and rerun only what did not pass.
6. **Report honestly.** Record failures in `STATUS.md` and in the `status` field of `manifest.yaml`, with the
   log excerpt.
   * Do not attempt invasive fixes; continue with the other codes and report at the end.
   * Never mark a step as passed that you did not run.
7. **Shell hygiene.**
   * Some shells alias `grep` to buffering tools; use `/usr/bin/grep` when piping live output.
   * macOS has no `timeout` command.
   * Don't edit a shell script while it is running, because bash reads scripts incrementally.

## Install: the standard sequence

Check the platform first (`uname -sm`). Supported: macOS arm64 (osx-arm64) and Linux x86_64 (linux-64). On a
Mac, ExaChem runs in an arm64 Linux container (linux-aarch64).

```bash
git submodule update --init --recursive       # or: bash scripts/fetch_all.sh (plain git, no pixi)
pixi install -e qed-psi4 --frozen             # Psi4 1.10.2 + hilbert, cqed-scf, qed-ci, psi4polaritonic, pdaggerq
pixi install -e qed-pyscf --frozen            # PySCF 2.11.0 + OpenMS (editable)
pixi install -e qed-compiled --frozen         # toolchains for eT and Octopus
```

Builds, through the ledger. Set `JOBS` to about half the cores if other work is running.
* **build-hilbert** (60 min first time):
  `python3 scripts/job.py run build-hilbert --est 60 -- env JOBS=6 pixi run -e qed-psi4 build-hilbert`
* **build-qed-ci** (1 min):
  `python3 scripts/job.py run build-qed-ci --est 1 -- pixi run -e qed-psi4 build-qed-ci`
* **build-pdaggerq** (5 min):
  `python3 scripts/job.py run build-pdaggerq --est 5 -- pixi run -e qed-psi4 build-pdaggerq`
* **build-et** (10 min; builds libcint first):
  `python3 scripts/job.py run build-et --est 10 -- pixi run -e qed-compiled build-et`
* **build-octopus** (20 min):
  `python3 scripts/job.py run build-octopus --est 20 -- pixi run -e qed-compiled build-octopus`

cqed-scf, psi4polaritonic and OpenMS need no build. Then run each package's own shortest test, and the smoke
tests. Both run in `smoke/work/`, so nothing is written into `src/`:

```bash
pixi run -e qed-psi4 test-hilbert             # also test-cqed-scf, test-qed-ci, test-psi4polaritonic, test-pdaggerq
pixi run -e qed-pyscf test-openms
pixi run -e qed-compiled test-et              # also test-octopus
pixi run -e qed-psi4 python smoke/hilbert_smoke.py   # one smoke/<code>_smoke.* per code -> results/<code>.json
```

ExaChem (Linux only):
* On a Mac, ask first, then:

  ```bash
  colima start --vm-type vz --cpu 6 --memory 12 --disk 100
  pixi run exachem-image
  JOBS=4 pixi run exachem-build
  pixi run exachem-run
  pixi run exachem-smoke
  ```

  * `exachem-build` takes about 1.5 h and fetches about 0.5 GB of dependencies.
  * Use `EXACHEM_CLEAN=1` for a clean rebuild.
  * `colima stop` frees the VM afterwards.
* On linux-64, use `pixi install -e qed-linux --frozen && pixi run -e qed-linux build-exachem-native`, with
  `EXACHEM_WORK` set to a writable build location.

On an HPC cluster: after installing, run `pixi run hooks`, then point the user to `modulefiles/qed-code/*.lua`
(Lmod `source_sh` of `hooks/<env>.sh`). Hooks contain absolute paths, so regenerate them after every install.

## Verifying an install

* The ledger shows `passed` for each build and test step: `python3 scripts/job.py show`.
* `results/<code>.json` exists for each code.
* For the common case (H2O/STO-3G, Bohr geometry in `smoke/common.py`, lambda = (0, 0, 0.05) a.u.,
  omega = 0.5 Eh), the expected values on osx-arm64 are as follows. Differences up to about 1e-7 Eh are normal;
  larger ones mean something is wrong.

  | code | QED-HF (Eh) | correlated (Eh) |
  |---|---|---|
  | hilbert, cqed-scf, psi4polaritonic, qed-ci, OpenMS | −74.958643777571 | hilbert QED-CCSD-21: −75.008881488252; qed-ci QED-FCI (1 photon): −75.008999295837 |
  | ExaChem | −74.958643802 | QED-CCSD (2 photons): −75.008882029 |
  | eT | −74.961427212608 | QED-CCSD: −75.011687107629 |

  The 2.8 mEh difference in eT's QED-HF has been reproduced and is not an install error. It is most likely
  eT's one-electron dipole self-energy convention, but that is not yet confirmed.
* Octopus should reproduce its own test-suite value for pxLDA hydrogen: total energy −0.44049659 ± 3e-7.
* pdaggerq produces equations, not numbers.
* `git status` must be clean, and `git submodule foreach git status --short` must print nothing.

## Known pitfalls (already handled; don't "fix" them again)

* **Psi4 1.10.2** needs `einsums 1.1.5`; 1.1.6 breaks `import psi4`. **Stock PySCF 2.11.0** needs
  `numpy < 2.4`. Both are pinned in `pixi.toml`.
* **conda-forge compilers** no longer export `CC`/`CXX`/`FC`. The build scripts default to `cc`/`c++`/`gfortran`.
* On **linux-64**, qed-ci builds with `BACKEND=openblas` and needs `cblas.h`. `libopenblas` ships no headers, so
  the qed-ci feature adds `openblas` for linux-64 (macOS uses Accelerate).
* **git** comes from the env (hilbert, pdaggerq, qed-linux) for CMake FetchContent, because clusters may lack a system
  git or keep it in a module.
* `scripts/job.py` creates `logs/` itself (it is untracked, so a fresh clone has none).
* On **macOS**:
  * plain `make` needs `SDKROOT` (qed-ci);
  * Octopus needs GNU `cpp` and has its SPARSKIT lookup disabled;
  * hilbert needs `-Wno-invalid-specialization` for clang ≥ 21 (BTAS headers).
* **ExaChem/TAMM:**
  * `-DALLOW_CONDA=ON` is needed because pixi sets `CONDA_PREFIX`;
  * pass `-DCMSB_TAG` equal to the release tag;
  * `cmake < 4`;
  * the conda `binutils` package provides `ar`;
  * the container needs `--shm-size=4g` for GlobalArrays.
* **Name clash:** qed-ci and psi4polaritonic both ship `helper_cqed_rhf.py`, and both are on `PYTHONPATH`
  in `qed-psi4`. Scripts must insert the intended directory first on `sys.path`.
* **PYTHONPATH:** each code adds its entry through `scripts/activate/<code>.sh`, because pixi keeps only one
  value per `activation.env` key across features. Don't move these into `activation.env`.
* **Python bytecode** goes to `build/pycache` via `PYTHONPYCACHEPREFIX`, to keep `src/` clean.
* **cqed-scf** is used via `PYTHONPATH`, not an editable install, because its repo tracks an egg-info folder
  that an editable install would rewrite.
* **Mac `.pixi/envs`** are visible inside the container through the read-only mount. pixi warns about them and
  installs to the detached path; this is expected.

## Conventions differ between codes

Before comparing numbers across codes, check the `conventions` block in `manifest.yaml` and in
`results/<code>.json`. The main differences:
* the coupling definition (hilbert takes `g = lambda / sqrt(2 omega)`, the others take lambda);
* coherent state or Fock-basis reference;
* how the dipole self-energy is treated;
* whether the nuclear dipole is included;
* photon truncation (QED-CCSD with 1 photon vs 2 photons).

## Making changes (only when asked)

* **New code:** add it to `scripts/add_submodules.sh` (pinned commit or tag) and run that. Then:
  * add a pixi feature and an env assignment, a `scripts/build/<code>.sh`, a `scripts/test/<code>.sh` and a
    `smoke/<code>_smoke.*`;
  * add a `manifest.yaml` entry.

  Commit after each coherent step.
* **Pin update:** check out the new commit in `src/<code>`, `git add src/<code>`, update `manifest.yaml`,
  rebuild, retest and re-smoke-test.
* **Commit messages:** short imperative subject; describe build fixes precisely, because the history is the
  record of what was needed.
