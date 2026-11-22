#!/bin/sh
# make install の前に、要るものがそろっているかを確かめます。
#
#   tools/prepare.sh          足りないものを、Homebrew があれば入れます
#   tools/prepare.sh --check  確かめるだけで、何も入れません
#
# 自動で入れるのは、ビルドに要る Go と gh だけです。ログインが要るものと、
# どちらを使うかを選ぶもの（Codex、Claude Code）は、入れ方を案内します。

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
		if have brew; then todo "$3" "brew install $2 で入ります。make install が自動で入れます。"; else todo "$3" "$4"; fi
		return
	fi
	printf '  入れる  %s（brew install %s）\n' "$3" "$2"
	if brew install "$2" >/dev/null 2>&1 && have "$1"; then
		ok "$3"
	else
		todo "$3" "brew install $2 が失敗しました。手で実行して、出た内容を確かめてください。"
	fi
}

echo "要るものを確かめます。"

if have git; then ok "Git"; else todo "Git" "xcode-select --install で、Xcode のコマンドライン ツールを入れてください。"; fi
brew_install go go "Go（lacia をビルドします）" "https://go.dev/dl/ から入れるか、Homebrew（https://brew.sh/）を入れてから、やり直してください。"

# 手元のソースからビルドするときは、GitHub から取得しません。
if [ -z "$LACIA_SRC" ] && have git; then
	if GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/imos/lacia.git HEAD >/dev/null 2>&1; then
		ok "imos/lacia を読む権限"
	else
		brew_install gh gh "gh（GitHub の認証に使います）" "https://cli.github.com/ から入れてください。"
		if have gh && ! gh auth status >/dev/null 2>&1; then
			todo "GitHub へのログイン" "gh auth login のあと、gh auth setup-git を実行してください。"
		elif have gh; then
			todo "imos/lacia を読む権限" "gh auth setup-git を実行してください。それでも読めないときは、リポジトリーの権限を、ひな形を案内した方に確かめてください。"
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
*":$prefix/bin:"*) ok "PATH に $prefix/bin" ;;
*) hint "PATH に $prefix/bin がありません" "シェルの設定（~/.zshrc など）に、export PATH=\"$prefix/bin:\$PATH\" を足してください。" ;;
esac

# 通知アプリは、入れなくても使えます。
if have swiftc && have python3; then
	ok "通知アプリのビルドに要るもの（swiftc、python3）"
else
	hint "通知アプリ（make notifier）を使うとき" "xcode-select --install で、Xcode のコマンドライン ツールを入れてください。入れなくても、ほかは使えます。"
fi

if [ "$missing" = 1 ]; then
	echo
	echo "足りないものがあります。上の案内のとおりにそろえてから、make install をやり直してください。"
	exit 1
fi
[ "$advice" = 1 ] && echo && echo "「案内」の項目は、あとからでも構いません。"
exit 0
