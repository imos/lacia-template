#!/bin/sh
# LACIA_SOURCE に書いたリポジトリーから、指定した版の本体をGitで取得します。
#
#   tools/checkout-source.sh source                   取得先を表示します
#   tools/checkout-source.sh check                    取得先を読めるかを確かめます
#   tools/checkout-source.sh checkout <ディレクトリー> [版]
#   tools/checkout-source.sh revision <実行ファイル> [clean]
#
# LACIA_SOURCE がない記録では、配布用本体を取得します。
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
repo=""
if [ -f "$root/LACIA_SOURCE" ]; then
    repo=$(tr -d ' \t\r\n' <"$root/LACIA_SOURCE")
fi
[ -n "$repo" ] || repo=https://github.com/imos/lacia.git

case "${1:-}" in
source)
    printf '%s\n' "$repo"
    ;;
check)
    GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code "$repo" HEAD >/dev/null
    ;;
checkout)
    dir=$2
    revision=${3:-HEAD}
    git init -q "$dir"
    GIT_TERMINAL_PROMPT=0 git -C "$dir" fetch --quiet --depth=1 -- "$repo" "$revision"
    git -C "$dir" checkout --quiet --detach FETCH_HEAD
    ;;
revision)
    metadata=$(go version -m "$2")
    printf '%s\n' "$metadata" | awk -F= -v check="${3:-}" '
        $1 ~ /^[[:space:]]+build[[:space:]]+vcs\.revision$/ { revision = $2 }
        $1 ~ /^[[:space:]]+build[[:space:]]+vcs\.modified$/ { modified = $2 }
        END {
            if (revision == "" || (check == "clean" && modified != "false")) exit 1
            print revision
        }
    '
    ;;
*)
    printf '%s\n' '取得先には source、読み取りの点検には check、本体の取得には checkout <ディレクトリー> [版]、入っている版の確認には revision <実行ファイル> を指定してください。' >&2
    exit 2
    ;;
esac
