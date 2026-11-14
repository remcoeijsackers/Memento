#!/usr/bin/env python3
"""Drive the interactive picker through a real pseudo-terminal.

Covers the built-in picker and fzf, in bash and zsh:
filtering, arrow keys, the main menu and cancelling.

    pip install pexpect && python3 tests/interactive.py
"""

import os
import re
import shutil
import sys
import tempfile
import time

try:
    import pexpect
except ImportError:
    print("skipped: pip install pexpect to run the interactive tests")
    sys.exit(0)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MTO = os.path.join(ROOT, "bin", "mto")
ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
failures = 0


def pump(p, until, secs=8):
    """Read output until the regex matches; answer cursor-position queries (fzf asks for them)."""
    buf, end = "", time.time() + secs
    while time.time() < end:
        try:
            chunk = p.read_nonblocking(4096, timeout=0.2)
        except pexpect.TIMEOUT:
            chunk = ""
        if "\x1b[6n" in chunk:
            p.send("\x1b[5;1R")
        buf += chunk
        if re.search(until, ANSI.sub("", buf)):
            return ANSI.sub("", buf)
    raise AssertionError(f"timed out waiting for {until!r}; screen ended with {ANSI.sub('', buf)[-200:]!r}")


def check(label, got, want):
    global failures
    ok = got == want
    failures += not ok
    print(f"{'ok  ' if ok else 'FAIL'} {label}: {got!r}" + ("" if ok else f" (wanted {want!r})"))


def where(p):
    p.sendline('echo AT"$PWD"END')
    p.expect(r"AT(/[^\r\n]*)END")
    path = p.match.group(1)
    p.expect("PROMPT> ")
    return path


def main():
    home = tempfile.mkdtemp(prefix="mto-pty-")
    projects = os.path.join(home, "p")
    for d in ("website", "api", "docs"):
        os.makedirs(os.path.join(projects, d))
    env = {
        "HOME": home, "MEMENTO_HOME": os.path.join(home, ".mto"), "TERM": "xterm-256color",
        "PATH": os.environ["PATH"], "PS1": "PROMPT> ", "PROMPT": "PROMPT> ", "NO_COLOR": "1",
    }
    for d in ("website", "api", "docs"):
        pexpect.run(f"bash {MTO} tag {d} {os.path.join(projects, d)}", env=env)
    pexpect.run(f"bash {MTO} alias sayok 'echo ran-alias-ok'", env=env)

    shells = [("bash", "bash --norc --noprofile -i")]
    if shutil.which("zsh"):
        shells.append(("zsh", "zsh -f -i"))
    pickers = ["builtin"] + (["fzf"] if shutil.which("fzf") else [])

    for shell, cmd in shells:
        for picker in pickers:
            env["MEMENTO_NO_FZF"] = "1" if picker == "builtin" else ""
            label = f"{shell}/{picker}"
            p = pexpect.spawn(cmd, env=env, encoding="utf-8", timeout=10, dimensions=(30, 110))
            pump(p, r"PROMPT> $")
            p.sendline(f'eval "$({MTO} init {shell})"; cd /')
            pump(p, r"PROMPT> $")

            p.sendline("mto go")
            pump(p, r"3/3")
            p.send("api")
            time.sleep(0.4)
            p.send("\r")
            pump(p, r"PROMPT> $")
            check(f"{label} filter + enter", where(p), os.path.join(projects, "api"))

            p.sendline("cd / && mto go")
            pump(p, r"3/3")
            p.send("\x1b[B")
            p.send("\x1b[B")
            time.sleep(0.4)
            p.send("\r")
            pump(p, r"PROMPT> $")
            check(f"{label} arrows + enter", where(p), os.path.join(projects, "docs"))

            if picker == "builtin":
                p.sendline("mto")
                pump(p, r"Run an alias")
                p.send("run an")
                pump(p, r"1/\d")
                p.send("\r")
                pump(p, r"aliases")
                p.send("\r")
                screen = pump(p, r"PROMPT> $")
                check(f"{label} menu runs an alias", "ran-alias-ok" in screen, True)

                p.sendline("mto go")
                pump(p, r"3/3")
                p.send("\x07")  # ctrl-g cancels
                pump(p, r"PROMPT> $")
                p.sendline('echo ST"$?"US')
                p.expect(r"ST(\d+)US")
                check(f"{label} cancel exit status", p.match.group(1), "130")

            p.sendline("exit")
            p.expect(pexpect.EOF)

    shutil.rmtree(home, ignore_errors=True)
    print("all interactive tests passed" if not failures else f"{failures} interactive test(s) failed")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
