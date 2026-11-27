#!/bin/sh
# make install に必要なツールと、本体を読み取れるかどうかを確かめます。
#
#   tools/prepare.sh          Homebrewがあれば、足りないGoやghをインストールします
#   tools/prepare.sh --check  確かめるだけで、何も入れません
#
# GitHubへのログインや、会話に使うCodexかClaude Codeの準備が必要なときは、手順を案内します。

check_only=""
[ "$1" = "--check" ] && check_only=1
prefix="${PREFIX:-$HOME/.local}"
missing=0
advice=0

have() { command -v "$1" >/dev/null 2>&1; }
ok() { printf '  ある    %s\n' "$1"; }
todo() { printf '  ない    %s\n          %s\n' "$1" "$2"; missing=1; }
hint() { printf '  案内    %s\n          %s\n' "$1" "$2"; advice=1; }

# brew_install <コマンド> <パッケージ> <説明> <Homebrew がないときの案内>
brew_install() {
	if have "$1"; then ok "$3"; return; fi
	if [ -n "$check_only" ] || ! have brew; then
		if have brew; then todo "$3" "make install で自動的に入ります。ご自分で入れるときは brew install $2 を実行してください。"; else todo "$3" "$4"; fi
		return
	fi
	printf '  入れる  %s（brew install %s）\n' "$3" "$2"
	if brew install "$2" >/dev/null 2>&1 && have "$1"; then
		ok "$3"
	else
		todo "$3" "brew install $2 に失敗しました。このコマンドをターミナルで実行し、エラーの内容を確かめてください。"
	fi
}

echo "インストールに必要なものを確かめます。"

if have git; then ok "Git"; else todo "Git" "xcode-select --install で、Xcode のコマンドライン ツールを入れてください。"; fi
brew_install go go "Go（lacia をビルドします）" "https://go.dev/dl/ から入れるか、Homebrew（https://brew.sh/）を入れてから、やり直してください。"

# 手元のソースからビルドするときは、GitHub から取得しません。取得先は、LACIA_SOURCE にあります。
if [ -z "$LACIA_SRC" ] && have git; then
	lacia_source=$("$(dirname "$0")/checkout-source.sh" source)
	if "$(dirname "$0")/checkout-source.sh" check >/dev/null 2>&1; then
		ok "本体（${lacia_source}）を読む権限"
	else
		brew_install gh gh "gh（GitHub の認証に使います）" "https://cli.github.com/ から入れてください。"
		if have gh && ! gh auth status >/dev/null 2>&1; then
			todo "GitHub へのログイン" "gh auth login のあと、gh auth setup-git を実行してください。"
		elif have gh; then
			todo "本体（${lacia_source}）を読む権限" "gh auth setup-git を実行してください。それでも読めないときは、このリポジトリーを読めるか、ひな形を案内した方にお尋ねください。"
		fi
	fi
fi

if have codex || have claude; then
	have codex && ok "Codex"
	have claude && ok "Claude Code"
else
	todo "Codex か Claude Code" "どちらかを入れて、ログインしてください。brew install --cask codex か、brew install --cask claude-code で入ります。"
fi

case ":$PATH:" in
*":$prefix/bin:"*) ok "PATH の $prefix/bin" ;;
*) hint "PATH に $prefix/bin がありません" "シェルの設定（~/.zshrc など）に、export PATH=\"$prefix/bin:\$PATH\" を足してください。" ;;
esac

# 通知アプリを使うときだけ、swiftcとpython3が必要です。
if have swiftc && have python3; then
	ok "通知アプリのビルドに要るもの（swiftc、python3）"
else
	hint "通知アプリ（make notifier）を使うとき" "xcode-select --install で、Xcode のコマンドライン ツールを入れてください。通知を使わない方は、この準備を省けます。"
fi

if [ "$missing" = 1 ]; then
	echo
	echo "足りないものがあります。上の案内のとおりにそろえてから、make install をやり直してください。"
	exit 1
fi
[ "$advice" = 1 ] && echo && echo "「案内」の項目は、必要になってから設定できます。"
exit 0
