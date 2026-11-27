#!/bin/sh
# 選んだソースで実行ファイルを作り、動くことを確かめてから入れ替えます。
set -eu

mode=$1
binary=$2
checkout=$(dirname "$0")/checkout-source.sh
src=${LACIA_SRC:-}
ref=${LACIA_REF:-}

if [ -n "$src" ] && [ -n "$ref" ]; then
    echo '手元のソースは LACIA_SRC で、取得する版は LACIA_REF で指定します。今回はどちらか一方を指定してください。' >&2
    exit 1
fi

previous=""
if [ -x "$binary" ]; then
    previous=$("$checkout" revision "$binary" 2>/dev/null) || previous=""
    if [ "$mode" = binary ] && [ -z "$src" ] && [ -z "$ref" ]; then
        "$binary" rules list >/dev/null
        echo 'インストール済みの lacia を使います。版を更新するときは make update を実行してください。'
        exit 0
    fi
fi

dir=$(dirname "$binary")
mkdir -p "$dir"
build=$(mktemp -d "$dir/.lacia-install.XXXXXX")
build=$(cd "$build" && pwd)
trap 'rm -rf "$build"' 0

if [ -z "$src" ]; then
    src="$build/source"
    "$checkout" checkout "$src" "$ref"
fi

(cd "$src" && go build -o "$build/lacia" ./cmd/lacia)
"$build/lacia" rules list >/dev/null
installed=$("$checkout" revision "$build/lacia" 2>/dev/null) || installed=""
if [ -z "${LACIA_SRC:-}" ] && [ "$installed" != "$(git -C "$src" rev-parse HEAD)" ]; then
    echo '実行ファイルに取得したコミットが記録されませんでした。既存の lacia を使い続けられます。' >&2
    exit 1
fi

mv -f "$build/lacia" "$binary"
if [ -n "$installed" ]; then
    printf 'インストールした lacia のコミットは %s です。\n' "$installed"
fi
if [ -n "$previous" ] && [ "$previous" != "$installed" ]; then
    printf '更新前の lacia のコミットは %s です。\n' "$previous"
fi
