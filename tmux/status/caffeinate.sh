#!/bin/bash
# Shows a coffee icon in the tmux status bar while something keeps the Mac awake through cafe-on
# (bin/cafe.py): the icon alone for your persistent launchd job (com.santiago.caffeinate), the
# number of agents holding their own after it, and +N when both (after a space, or the icon draws
# small). Claude Code's transient one doesn't count.
# Icon: nf-fa-coffee (U+F0F4) emitted as raw UTF-8 bytes — macOS system
# bash 3.2 runs this and its printf expands \x but not \U escapes.
agents=0
for hold in "$HOME"/.cache/cafe/*; do
  [ -f "$hold" ] || continue
  read -r pid _ < "$hold"
  kill -0 "$pid" 2>/dev/null && agents=$((agents + 1))
done

launchctl list 2>/dev/null | grep -q com.santiago.caffeinate && yours=1 || yours=0

if [ "$yours" = 1 ] && [ "$agents" -gt 0 ]; then
  printf '\xef\x83\xb4 +%d  ' "$agents"
elif [ "$agents" -gt 0 ]; then
  printf '\xef\x83\xb4 %d  ' "$agents"
elif [ "$yours" = 1 ]; then
  printf '\xef\x83\xb4  '
fi
