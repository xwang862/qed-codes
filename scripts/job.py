#!/usr/bin/env python3
"""Resumable job runner and ledger for the qed-codes collection (stdlib only).

Run a step (its output goes line by line to logs/<step>.log; status.json and STATUS.md are rewritten
when the step starts and ends; a step that already passed is skipped unless --force):

    python3 scripts/job.py run <step> [--est MIN] [--force] -- <command ...>

Record a step by hand (e.g. skipped, or a manual action), or list the ledger:

    python3 scripts/job.py mark <step> <state> [--note TEXT]
    python3 scripts/job.py show

A step that was "running" when the machine stopped shows as "running" with a dead pid; rerun it.
Commands run from the project root with the current environment. On failure the last 25 log lines
are stored in the ledger and in STATUS.md.
"""

import argparse
import fcntl
import json
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LEDGER = os.path.join(ROOT, "status.json")
STATUS_MD = os.path.join(ROOT, "STATUS.md")
LOCK = os.path.join(ROOT, "logs", ".ledger.lock")


def now():
    return time.strftime("%Y-%m-%d %H:%M:%S")


def update(step, **fields):
    """Merge fields into the ledger entry of step and rewrite STATUS.md (under a file lock)."""
    os.makedirs(os.path.dirname(LOCK), exist_ok=True)
    with open(LOCK, "w") as lk:
        fcntl.flock(lk, fcntl.LOCK_EX)
        st = json.load(open(LEDGER)) if os.path.exists(LEDGER) else {}
        if step is not None:
            st.setdefault(step, {}).update(fields)
            st[step]["updated"] = now()
        json.dump(st, open(LEDGER + ".tmp", "w"), indent=1)
        os.replace(LEDGER + ".tmp", LEDGER)
        write_md(st)
    return st


def write_md(st):
    lines = ["# qed-codes status", "", "Updated %s. Ledger: `status.json`; logs: `logs/<step>.log`; "
             "runner: `scripts/job.py`. See `manifest.yaml` for the codes." % now(), "",
             "| step | state | est | time | updated | note |", "|---|---|---|---|---|---|"]
    for k, v in st.items():
        t = "%.0f s" % v["seconds"] if "seconds" in v else ""
        est = "%s min" % v["est_min"] if v.get("est_min") else ""
        note = (v.get("note") or "").replace("|", "/").replace("\n", " ")
        lines.append("| `%s` | %s | %s | %s | %s | %s |" % (k, v.get("state", ""), est, t, v.get("updated", ""), note))
    fails = [(k, v) for k, v in st.items() if v.get("excerpt")]
    if fails:
        lines += ["", "## Log excerpts of failed steps"]
        for k, v in fails:
            lines += ["", "### `%s` (%s)" % (k, v.get("state")), "", "```", v["excerpt"].rstrip(), "```"]
    open(STATUS_MD, "w").write("\n".join(lines) + "\n")


def run(args):
    st = json.load(open(LEDGER)) if os.path.exists(LEDGER) else {}
    if st.get(args.step, {}).get("state") == "passed" and not args.force:
        print("skip %s (already passed)" % args.step, flush=True)
        return 0
    cmd = args.command[1:] if args.command[:1] == ["--"] else args.command
    log = os.path.join(ROOT, "logs", args.step + ".log")
    t0 = time.time()
    with open(log, "w", buffering=1) as fh:
        fh.write("# %s  %s\n# cmd: %s\n" % (args.step, now(), " ".join(cmd)))
        p = subprocess.Popen(cmd, cwd=ROOT, stdout=fh, stderr=subprocess.STDOUT)
        update(args.step, state="running", start=now(), pid=p.pid, est_min=args.est, log="logs/%s.log" % args.step,
               cmd=" ".join(cmd), excerpt=None, note=args.note)
        print("start  %s (pid %d, est %s min) -> %s" % (args.step, p.pid, args.est, log), flush=True)
        rc = p.wait()
    dt = time.time() - t0
    state = "passed" if rc == 0 else "FAILED (exit %d)" % rc
    excerpt = None
    if rc != 0:
        excerpt = "".join(open(log, errors="replace").readlines()[-25:])
    update(args.step, state=state, seconds=dt, end=now(), excerpt=excerpt, pid=None)
    print("finish %s %s %.0f s" % (args.step, state, dt), flush=True)
    return rc


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="what", required=True)
    r = sub.add_parser("run")
    r.add_argument("step")
    r.add_argument("--est", type=float, default=None)
    r.add_argument("--force", action="store_true")
    r.add_argument("--note", default=None)
    r.add_argument("command", nargs=argparse.REMAINDER)
    m = sub.add_parser("mark")
    m.add_argument("step")
    m.add_argument("state")
    m.add_argument("--note", default=None)
    sub.add_parser("show")
    args = ap.parse_args()
    if args.what == "run":
        sys.exit(run(args))
    if args.what == "mark":
        update(args.step, state=args.state, note=args.note)
    st = update(None)
    for k, v in st.items():
        print("%-32s %s" % (k, v.get("state")))


if __name__ == "__main__":
    main()
