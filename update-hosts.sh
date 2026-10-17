#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
printf 'Replace /etc/hosts using the local entries and the downloaded blocklist? (yes/no) '
read -r confirmation
[[ "$confirmation" == yes || "$confirmation" == y ]] || exit 0

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
url=https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts
curl --fail --show-error --silent --location "$url" -o "$work_dir/download"
local_hosts="$HOME/.hosts.local"
[[ -f "$local_hosts" ]] || local_hosts="$root/hosts.local"
{
    cat "$root/hosts"
    printf '\n'
    if [[ -f "$local_hosts" ]]; then
        cat "$local_hosts"
        printf '\n'
    fi
    cat "$work_dir/download"
    printf '\n'
} > "$work_dir/combined"

python3 - "$work_dir/download" "$work_dir/combined" <<'PY'
import ipaddress
import pathlib
import sys

for name in sys.argv[1:]:
    entries = 0
    for line in pathlib.Path(name).read_text().splitlines():
        fields = line.split('#', 1)[0].split()
        if not fields:
            continue
        if len(fields) < 2:
            sys.exit('Invalid hosts data; /etc/hosts was not changed.')
        try:
            ipaddress.ip_address(fields[0])
        except ValueError:
            sys.exit('Invalid hosts data; /etc/hosts was not changed.')
        entries += 1
    if not entries:
        sys.exit('Empty hosts data; /etc/hosts was not changed.')
PY

backup="/etc/hosts.dotfiles-$(date +%Y%m%d-%H%M%S)-$$"
sudo cp -p /etc/hosts "$backup"
sudo install -m 644 "$work_dir/combined" /etc/hosts
printf 'Updated /etc/hosts. Previous file: %s\n' "$backup"
