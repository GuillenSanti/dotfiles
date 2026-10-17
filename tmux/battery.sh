#!/bin/bash
# Battery indicator for tmux

info=$(pmset -g batt)
pct=$(echo "$info" | grep -Eo '\d+%' | head -1 | tr -d '%')

if [ -z "$pct" ]; then
  exit 0
fi

if [[ "$info" == *"; charging;"* ]]; then
  icon="󰂄"  # cargando (rayo)
elif [[ "$info" == *"; charged;"* ]]; then
  icon="󰚥"  # enchufado y lleno
elif [[ "$info" == *"'AC Power'"* ]]; then
  icon="󰚥"  # enchufado (sin cargar activamente, ej. al 80% con límite)
else
  icon="󰁹"  # en batería
fi

# Energy mode, only when it isn't Automatic: Low Power (leaf) or High Power (rocket)
case "$(pmset -g | awk '$1 == "powermode" || $1 == "lowpowermode" { print $1 "=" $2; exit }')" in
  powermode=1|lowpowermode=1) mode="󰌪 " ;;
  powermode=2) mode="󱓞 " ;;
  *) mode="" ;;
esac

echo "$mode$icon $pct%"
