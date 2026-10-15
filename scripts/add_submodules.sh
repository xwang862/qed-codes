#!/bin/bash
# One-time: add every code under src/<name> as a git submodule and check out its pinned commit.
# (On other machines use `git clone --recursive` or scripts/fetch_all.sh instead.)
set -euo pipefail
cd "$(dirname "$0")/.."
add() {   # name url commit-or-tag
  local name=$1 url=$2 pin=$3
  if [ ! -e "src/$name/.git" ]; then
    echo "== add $name ($url @ $pin)"
    git submodule add "$url" "src/$name"
  fi
  git -C "src/$name" fetch --tags --quiet origin || true
  git -C "src/$name" checkout --quiet "$pin"
  git -C "src/$name" submodule update --init --recursive
  echo "   $name at $(git -C src/$name rev-parse HEAD)"
  git add .gitmodules "src/$name"
  git diff --cached --quiet || git commit -q -m "Add $name submodule at $pin"
}
add hilbert         https://github.com/edeprince3/hilbert.git          5d29fcd5d535fe9348e7af1108ad8cb34a54aa75
add cqed-scf        https://github.com/FoleyLab/cqed-scf.git           7f2f82ff606e2335292c9417b97e403af22c3ef9
add qed-ci          https://github.com/FoleyLab/qed-ci.git             747212217d41ae86d58196d9c50cfce28ef286cb
add psi4polaritonic https://github.com/FoleyLab/psi4polaritonic.git    689bf14fd2d9c9f987956d42f8d0629968e9fa47
add pdaggerq        https://github.com/edeprince3/pdaggerq.git         05b6fca4d3dd89be96d3548830bd498145b2f97a
add OpenMS          https://github.com/lanl/OpenMS.git                 86ff94d051e00b1240e504c5fc4d80ceaa79bdcf
add eT              https://gitlab.com/eT-program/eT.git               v2.6.1
add octopus         https://gitlab.com/octopus-code/octopus.git        16.4
add exachem         https://github.com/ExaChem/exachem.git             v0.1.0
add TAMM            https://github.com/NWChemEx/TAMM.git               v0.1.0
echo "all submodules added"
