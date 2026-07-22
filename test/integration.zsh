#!/bin/zsh
set -euo pipefail

repo=${0:A:h:h}
cli="$repo/bin/poopsbgone"
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/poopsbgone-integration.XXXXXX")
chmod 700 "$tmpdir"
image="$tmpdir/volume.dmg"
mountpoint=
device=

cleanup() {
  local exit_code=$?
  trap - EXIT HUP INT TERM
  if [[ -n "$device" ]]; then
    hdiutil detach "$device" -force >/dev/null 2>&1 || true
  fi
  rm -rf -- "$tmpdir"
  exit $exit_code
}
trap cleanup EXIT HUP INT TERM

hdiutil create -quiet -size 16m -fs MS-DOS -volname PBGTEST "$image"
attach_output=$(hdiutil attach -nobrowse "$image")
attach_line=${${(f)attach_output}[-1]}
device=${attach_line%%$'\t'*}
mountpoint=${attach_line##*$'\t'}
[[ "$mountpoint" == /Volumes/* && -d "$mountpoint" ]]

weird_dir=$'odd\n\e[31mname'
mkdir -p "$mountpoint/folder" "$mountpoint/$weird_dir" \
  "$mountpoint/.Spotlight-V100" "$mountpoint/.Trashes"
print sentinel >"$mountpoint/keep.txt"
print metadata >"$mountpoint/folder/.DS_Store"
print metadata >"$mountpoint/$weird_dir/.DS_Store"
print sidecar >"$mountpoint/._keep.txt"
print index >"$mountpoint/.Spotlight-V100/index"
print trash >"$mountpoint/.Trashes/item"

before=$(find -x "$mountpoint" -print | LC_ALL=C sort)
preview=$("$cli" "$mountpoint")
after=$(find -x "$mountpoint" -print | LC_ALL=C sort)
[[ "$before" == "$after" ]]
[[ "$preview" == *'.DS_Store'* && "$preview" == *'._keep.txt'* ]]
[[ "$preview" != *$'\e'* && "$preview" == *'\n'* ]]

"$cli" --apply "$mountpoint"
[[ -f "$mountpoint/keep.txt" ]]
[[ ! -e "$mountpoint/folder/.DS_Store" ]]
[[ ! -e "$mountpoint/$weird_dir/.DS_Store" ]]
[[ ! -e "$mountpoint/._keep.txt" ]]
[[ ! -e "$mountpoint/.Spotlight-V100" ]]
[[ -e "$mountpoint/.Trashes/item" ]]

"$cli" --apply --include-trashes "$mountpoint"
[[ ! -e "$mountpoint/.Trashes" ]]

"$cli" --apply --eject "$mountpoint"
device=
[[ ! -e "$mountpoint" ]]

print -r -- "integration ok"
