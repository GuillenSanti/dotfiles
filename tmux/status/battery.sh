#!/bin/bash
# Battery indicator for tmux

info=$(pmset -g batt)
pct=$(echo "$info" | grep -Eo '\d+%' | head -1 | tr -d '%')

if [ -z "$pct" ]; then
  exit 0
fi

if [[ "$info" == *"; charging;"* ]]; then
  icon="󰂄"  # charging (lightning bolt)
elif [[ "$info" == *"; charged;"* ]]; then
  icon="󰚥"  # plugged in and full
elif [[ "$info" == *"'AC Power'"* ]]; then
  icon="󰚥"  # plugged in without charging, e.g. at an 80% charge limit
else
  icon="󰁹"  # on battery
fi

# Energy mode, only when it isn't Automatic: Low Power (leaf) or High Power (rocket)
case "$(pmset -g | awk '$1 == "powermode" || $1 == "lowpowermode" { print $1 "=" $2; exit }')" in
  powermode=1|lowpowermode=1) mode="󰌪 " ;;
  powermode=2) mode="󱓞 " ;;
  *) mode="" ;;
esac

echo "$mode$icon $pct%"
