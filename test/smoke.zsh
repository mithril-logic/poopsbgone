#!/bin/zsh
set -euo pipefail

repo=${0:A:h:h}
cli="$repo/bin/poopsbgone"
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/poopsbgone-smoke.XXXXXX")
chmod 700 "$tmpdir"

cleanup() {
  local exit_code=$?
  trap - EXIT HUP INT TERM
  rm -rf -- "$tmpdir"
  exit $exit_code
}
trap cleanup EXIT HUP INT TERM

out="$tmpdir/out"
err="$tmpdir/err"

zsh -n "$cli" "$repo/test/smoke.zsh" "$repo/test/integration.zsh"
"$cli" --help >"$out"
grep -q -- '--include-trashes' "$out"
grep -q -- 'exact mount root' "$out"
[[ "$("$cli" --version)" == 0.1.0 ]]

if "$cli" >"$out" 2>"$err"; then
  print -ru2 -- "expected a missing path to be refused"
  exit 1
fi
grep -q "missing volume path" "$err"

if "$cli" --unknown >"$out" 2>"$err"; then
  print -ru2 -- "expected an unknown option to be refused"
  exit 1
fi
grep -q "unknown option" "$err"

if "$cli" $'--bad\n\e[31m' >"$out" 2>"$err"; then
  print -ru2 -- "expected a control-character option to be refused"
  exit 1
fi
[[ "$(<"$err")" != *$'\e'* ]]
grep -Fq '\n' "$err"

if "$cli" "$repo" >"$out" 2>"$err"; then
  print -ru2 -- "expected a non-/Volumes path to be refused"
  exit 1
fi
grep -q "refusing non-/Volumes path" "$err"

print -r -- "smoke ok"
