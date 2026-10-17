#!/usr/bin/python3
"""Keeps the Mac awake while agents work. Linked as cafe-on, cafe-off and cafe-status in ~/.local/bin.

macOS sleeps only once no caffeinate is left, so each agent (Claude Code, opencode, Codex) gets its own:
from an agent, cafe-on starts that agent's caffeinate and cafe-off stops only that one, so another agent
still working keeps the Mac awake. An agent's caffeinate also ends with the agent (caffeinate -w), in
case it never calls cafe-off. From your own shell, cafe-on and cafe-off switch the persistent one, as
before: the launchd job com.santiago.caffeinate, until cafe-off. cafe-off --all turns everything off,
agents' included (say, before leaving on battery).

~/.cache/cafe holds a file per agent keeping it awake: named after the agent's pid, with its
caffeinate's pid, its tmux window and since when. tmux/caffeinate.sh shows them in the status bar.
"""

import datetime
import os
import re
import signal
import subprocess
import sys
import time

HOLDS = os.path.expanduser("~/.cache/cafe")
JOB = "com.santiago.caffeinate"
CAFFEINATE = ["/usr/bin/caffeinate", "-dims"]  # display, idle, disk and system sleep
AGENT = re.compile(r"^(\d+\.\d+\.\d+|claude|opencode|codex)$")  # Claude Code can show up as its version


def run(*cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def agent():
    """The pid of the agent this runs under, walking up the process tree; None from your own shell."""
    procs = {}
    for line in run("ps", "-Ao", "pid=,ppid=,comm=").splitlines():
        parts = line.split(None, 2)
        if len(parts) == 3 and parts[0].isdigit() and parts[1].isdigit():
            procs[int(parts[0])] = (int(parts[1]), os.path.basename(parts[2]))
    pid = os.getpid()
    while pid in procs and pid > 1:
        ppid, comm = procs[pid]
        if AGENT.match(comm):
            return pid
        pid = ppid
    return None


def alive_caffeinate(pid):
    return run("ps", "-o", "comm=", "-p", str(pid)).strip().endswith("caffeinate")


def holds():
    """(agent pid, caffeinate pid, window, since) of the agents keeping the Mac awake; forgets the ones gone."""
    found = []
    for name in sorted(os.listdir(HOLDS)) if os.path.isdir(HOLDS) else []:
        path = os.path.join(HOLDS, name)
        try:
            with open(path) as f:
                pid, window, since = f.read().rstrip("\n").split("\t")
        except (OSError, ValueError):
            pid = None
        if pid and pid.isdigit() and alive_caffeinate(int(pid)):
            found.append((int(name), int(pid), window, float(since)))
        else:
            os.remove(path)  # its agent ended, so did its caffeinate
    return found


def persistent():
    return JOB in run("launchctl", "list")


def window():
    pane = os.environ.get("TMUX_PANE")
    return run("tmux", "display", "-p", "-t", pane, "#{window_index}:#{window_name}").strip() if pane else ""


def refresh():
    if os.environ.get("TMUX"):
        run("tmux", "refresh-client", "-S")  # show the change in the status bar now


def others(mine):
    n = len([h for h in holds() if h[0] != mine]) + persistent()
    return f"{n} other {'one keeps' if n == 1 else 'ones keep'} it awake" if n else "nothing else keeps it awake"


def on():
    pid = agent()
    if pid is None:
        if not persistent():
            run("launchctl", "submit", "-l", JOB, "--", *CAFFEINATE)
        print("☕ ON until cafe-off")
        return
    if any(h[0] == pid for h in holds()):
        print("☕ already on for this agent")
        return
    # Its own session, so the agent's shell ending doesn't take it down: it lasts until cafe-off or the agent ends
    p = subprocess.Popen([*CAFFEINATE, "-w", str(pid)], start_new_session=True,
                         stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.makedirs(HOLDS, exist_ok=True)
    with open(os.path.join(HOLDS, str(pid)), "w") as f:
        f.write(f"{p.pid}\t{window()}\t{time.time()}\n")
    print("☕ ON for this agent, until its cafe-off or it ends")


def off():
    if "--all" in sys.argv[1:]:
        found = holds()
        for _, caffeinate, _, _ in found:
            os.kill(caffeinate, signal.SIGTERM)
        for name in os.listdir(HOLDS) if os.path.isdir(HOLDS) else []:
            os.remove(os.path.join(HOLDS, name))
        run("launchctl", "remove", JOB)
        print(f"😴 OFF for everyone ({len(found)} {'agent' if len(found) == 1 else 'agents'} included)")
        return
    pid = agent()
    if pid is None:
        run("launchctl", "remove", JOB)
        print(f"😴 OFF ({others(None)})")
        return
    for agent_pid, caffeinate, _, _ in holds():
        if agent_pid == pid:
            os.kill(caffeinate, signal.SIGTERM)
            os.remove(os.path.join(HOLDS, str(agent_pid)))
    print(f"😴 OFF for this agent ({others(pid)})")


def status():
    found, fixed = holds(), persistent()
    if not found and not fixed:
        print("😴 OFF")
        return
    if fixed:
        print("☕ ON until cafe-off")
    for _, _, where, since in found:
        print(f"☕ {where or 'an agent'}, since {datetime.datetime.fromtimestamp(since):%H:%M}")


def main():
    action = {"cafe-on": on, "cafe-off": off, "cafe-status": status}.get(os.path.basename(sys.argv[0]))
    action = action or {"on": on, "off": off, "status": status}.get(sys.argv[1] if len(sys.argv) > 1 else "")
    if not action:
        sys.exit("Usage: cafe-on | cafe-off [--all] | cafe-status  (or cafe.py on|off|status)")
    action()
    if action is not status:
        refresh()


if __name__ == "__main__":
    main()
