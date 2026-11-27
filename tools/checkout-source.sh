#!/bin/sh
# 固定した版の本体を、LACIA_SOURCE に書いた取得先から Git で取得します。
#
#   tools/checkout-source.sh source                   取得先を表示します
#   tools/checkout-source.sh check                    取得先を読めるかを確かめます
#   tools/checkout-source.sh checkout <ディレクトリー> <版>
#
# LACIA_SOURCE がない、以前の記録では、これまでの取得先を使います。
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
repo=""
if [ -f "$root/LACIA_SOURCE" ]; then
    repo=$(tr -d ' \t\r\n' <"$root/LACIA_SOURCE")
fi
[ -n "$repo" ] || repo=https://github.com/imos/lacia-dev.git

case "${1:-}" in
source)
    printf '%s\n' "$repo"
    ;;
check)
    GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code "$repo" HEAD >/dev/null
    ;;
checkout)
    dir=$2
    revision=$3
    git init -q "$dir"
    GIT_TERMINAL_PROMPT=0 git -C "$dir" fetch --quiet --depth=1 -- "$repo" "$revision"
    git -C "$dir" checkout --quiet --detach FETCH_HEAD
    ;;
*)
    printf '%s\n' 'source、check、checkout <ディレクトリー> <版> のどれかを指定してください。' >&2
    exit 2
    ;;
esac
