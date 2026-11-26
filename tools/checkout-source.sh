#!/bin/sh
# Go のモジュールパスを保ち、固定した開発版を Git から取得します。
set -eu

repo=https://github.com/imos/lacia-dev.git
case "${1:-}" in
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
    printf '%s\n' 'check か checkout <ディレクトリー> <版> を指定してください。' >&2
    exit 2
    ;;
esac
