#!/usr/bin/python3
"""Claude Code's status line, in the tmux dashboard's style.

Left: the model, its effort, ultracode (only while it's on), and the 5-hour and weekly limits with
when they reset. Right, at the pane's edge: how much of the context window the session uses.

Claude Code runs it after each event with the session's JSON on stdin (statusLine in
~/.claude/settings.json), so it stays quick: it reads that JSON, asks tmux how wide the pane is,
and looks for ultracode's markers in the session's transcript with rg.
"""

import datetime
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata


def fg(n):
    return f"\033[38;5;{n}m"


RESET = "\033[0m"
# The deck's palette (its dash_ui.py)
DIM, MUTED, TEXT, BRIGHT, LINE = fg(240), fg(244), fg(248), fg(252), fg(238)
BLUE, GREEN, YELLOW, RED, PURPLE = fg(110), fg(108), fg(179), fg(167), fg(140)
CHIP = "\033[48;5;236m"
ICON = {
    "model": "\U000f06a9",
    "effort": "\U000f04c5",
    "ultracode": "\U000f140b",
    "reset": "\U000f099b",
    "context": "\U000f035b",
}
DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
ANSI = re.compile(r"\033\[[0-9;]*m")
# Claude Code writes an ultra_effort_enter attachment on each prompt while ultracode is on, and an
# ultra_effort_exit when it goes off; /effort's own output says so as soon as you toggle it
ULTRACODE = r'"attachment":\{"type":"ultra_effort_(enter|exit)"|<local-command-stdout>[^"<]*Ultracode (on|off)'
INDENT = 2  # Claude Code draws the status line two columns in, and we keep two free at the right


def width(s):
    return sum(
        0 if unicodedata.combining(c) else 2 if unicodedata.east_asian_width(c) in "WF" else 1
        for c in ANSI.sub("", s)
    )


def level(pct):
    return RED if pct >= 80 else YELLOW if pct >= 50 else GREEN


def gauge(pct, w):
    n = max(0, min(w, round(pct / 100 * w)))
    return f"{level(pct)}{'━' * n}{LINE}{'─' * (w - n)}{RESET}"


def epoch(value):
    """resets_at as epoch seconds: Claude Code sends seconds, but take ms or ISO 8601 too."""
    if isinstance(value, (int, float)):
        return value / 1000 if value > 1e11 else value
    if isinstance(value, str):
        try:
            return datetime.datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
        except ValueError:
            return None
    return None


def limit(label, data, with_day):
    pct = (data or {}).get("used_percentage")
    if pct is None:
        return None
    pct = round(pct)
    text = f"{MUTED}{label}{RESET} {gauge(pct, 8)} {level(pct)}{pct}%{RESET}"
    at = epoch((data or {}).get("resets_at"))
    if at:
        when = datetime.datetime.fromtimestamp(at)
        day = f"{DAYS[when.weekday()]} " if with_day else ""
        text += f" {DIM}{ICON['reset']} {day}{when:%H:%M}{RESET}"
    return text


def tokens(n):
    return f"{n / 1_000_000:.1f}M".replace(".0M", "M") if n >= 1_000_000 else f"{round(n / 1000)}k"


def ultracode_on(transcript):
    """Whether the session's last ultracode marker says it's on. Needs rg: transcripts reach
    hundreds of MB, which rg searches in a few ms and grep in over a second."""
    rg = shutil.which("rg") or "/opt/homebrew/bin/rg"
    if not transcript or not os.path.isfile(transcript) or not os.access(rg, os.X_OK):
        return False
    try:
        out = subprocess.run([rg, "-o", "--no-filename", "--no-line-number", ULTRACODE, transcript],
                             capture_output=True, text=True, timeout=2).stdout
    except (OSError, subprocess.SubprocessError):
        return False
    last = out.strip().rsplit("\n", 1)[-1]
    return "ultra_effort_enter" in last or "Ultracode on" in last


def pane_width():
    """The tmux pane's width (Claude Code passes TMUX_PANE on), else the terminal's, else None."""
    pane = os.environ.get("TMUX_PANE")
    if pane:
        try:
            out = subprocess.run(["tmux", "display", "-p", "-t", pane, "#{pane_width}"],
                                 capture_output=True, text=True, timeout=1).stdout.strip()
            if out.isdigit():
                return int(out)
        except (OSError, subprocess.SubprocessError):
            pass
    try:
        with open("/dev/tty") as tty:
            return os.get_terminal_size(tty.fileno()).columns
    except OSError:
        return None


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        data = {}
    left = []
    model = (data.get("model") or {}).get("display_name")
    if model:
        left.append(f"{BLUE}{ICON['model']}{RESET} {BRIGHT}{model}{RESET}")
    effort = (data.get("effort") or {}).get("level")
    if effort:
        left.append(f"{MUTED}{ICON['effort']}{RESET} {TEXT}{effort}{RESET}")
    if ultracode_on(data.get("transcript_path")):
        left.append(f"{CHIP}{PURPLE} {ICON['ultracode']} ultracode {RESET}")
    limits = data.get("rate_limits") or {}
    for text in (limit("5h", limits.get("five_hour"), False), limit("7d", limits.get("seven_day"), True)):
        if text:
            left.append(" " + text)  # a wider gap before each limit
    line = "  ".join(left)

    ctx = data.get("context_window") or {}
    pct = ctx.get("used_percentage")
    if pct is not None:
        pct = round(pct)
        right = f"{MUTED}{ICON['context']} ctx{RESET} {gauge(pct, 10)} {level(pct)}{pct}%{RESET}"
        used, size = ctx.get("total_input_tokens"), ctx.get("context_window_size")
        if used and size:
            right += f"  {DIM}{tokens(used)}/{tokens(size)}{RESET}"
        cols = pane_width()
        room = (cols - 2 * INDENT) if cols else 0
        gap = room - width(line) - width(right)
        line += (" " * gap if gap >= 3 else "   ") + right
    sys.stdout.write(line)


if __name__ == "__main__":
    main()
