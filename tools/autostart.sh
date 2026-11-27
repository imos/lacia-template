#!/bin/sh
# macOSのlaunchdを使い、ログイン時にサーバーを自動で起動します。
#
#   tools/autostart.sh on <lacia> <設定ファイル> <状態のディレクトリー>
#   tools/autostart.sh off
#   tools/autostart.sh status
#
# ログイン中のユーザーのLaunchAgentに登録します。管理者権限は使いません。
# サーバーが止まると、launchdが起動し直します。起動を繰り返すときの間隔は最短30秒です。

set -e
label="${LACIA_LABEL:-jp.imoz.lacia.serve}"
plist="$HOME/Library/LaunchAgents/$label.plist"
target="gui/$(id -u)"

# 同じ名前のファイルがあれば、このサーバーの登録名が書かれているかを確かめます。
ours() { [ ! -e "$plist" ] || grep -q "<string>$label</string>" "$plist"; }

case "$1" in
on)
	lacia="$2"; config="$3"; state="$4"
	[ -x "$lacia" ] && [ -f "$config" ] && [ -n "$state" ] || { echo "lacia の実行ファイル、設定ファイル、状態を保存する場所が必要です。make install を済ませてから、make autostart を実行してください。"; exit 1; }
	ours || { echo "$plist がこのサーバーの設定かどうかを確かめられません。ファイルの登録名を確かめてください。"; exit 1; }
	mkdir -p "$HOME/Library/LaunchAgents" "$state"
	launchctl bootout "$target/$label" 2>/dev/null || true
	# launchd は、シェルの設定を読みません。Codex、Claude Code、Git を見つけられるように、
	# いまの PATH を書いておきます。
	cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key><string>$label</string>
	<key>ProgramArguments</key>
	<array><string>$lacia</string><string>serve</string><string>--config</string><string>$config</string></array>
	<key>EnvironmentVariables</key>
	<dict><key>PATH</key><string>$PATH</string></dict>
	<key>RunAtLoad</key><true/>
	<key>KeepAlive</key><true/>
	<key>ThrottleInterval</key><integer>30</integer>
	<key>ProcessType</key><string>Background</string>
	<key>StandardOutPath</key><string>$state/serve.log</string>
	<key>StandardErrorPath</key><string>$state/serve.log</string>
</dict>
</plist>
EOF
	chmod 600 "$plist"
	launchctl bootstrap "$target" "$plist"
	echo "ログイン時にサーバーを自動で起動するように設定しました。"
	echo "  ログは $state/serve.log で読めます。"
	echo "  自動起動をやめるときは make autostart-off を実行してください。"
	;;
off)
	ours || { echo "$plist がこのサーバーの設定かどうかを確かめられません。ファイルの登録名を確かめてください。"; exit 1; }
	launchctl bootout "$target/$label" 2>/dev/null || true
	rm -f "$plist"
	echo "サーバーの自動起動の設定を外しました。"
	;;
status)
	if launchctl print "$target/$label" >/dev/null 2>&1; then
		launchctl print "$target/$label" | grep -E '^	(state|pid|last exit code) =' || true
	else
		echo "サーバーの自動起動の登録を確かめられませんでした。"
	fi
	;;
*)
	echo "使い方: tools/autostart.sh on <lacia> <設定ファイル> <状態のディレクトリー> | off | status"
	exit 2
	;;
esac
