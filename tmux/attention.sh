#!/bin/bash
# Flags this pane's tmux window in the status bar while something waits for
# you (@attention); session-window-changed clears it on visit. Called by the
# Claude Code hooks, the opencode plugin and the zsh precmd hook.
# Usage: attention.sh done|ask   (no argument clears the flag)
# Icons: nf-md-bell_ring (U+F009E) and nf-md-help_circle (U+F02D7) as raw
# UTF-8 bytes — macOS system bash 3.2 printf expands \x but not \U escapes.
[ -n "$TMUX_PANE" ] || exit 0

case "$1" in
  done) icon=$(printf '\xf3\xb0\x82\x9e') ;;
  ask) icon=$(printf '\xf3\xb0\x8b\x97') ;;
  *) exec tmux set -wu -t "$TMUX_PANE" @attention ;;
esac

# Already looking at it: nothing to flag.
[ "$(tmux display -p -t "$TMUX_PANE" '#{window_active}')" = 1 ] && exit 0

tmux set -w -t "$TMUX_PANE" @attention "$icon"
