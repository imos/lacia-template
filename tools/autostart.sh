#!/bin/sh
# サーバーを、ログインのときに自動で起動するようにします（macOS の launchd）。
#
#   tools/autostart.sh on <lacia> <設定ファイル> <状態のディレクトリー>
#   tools/autostart.sh off
#   tools/autostart.sh status
#
# 登録するのは、自分のユーザーの LaunchAgent だけです。管理者の権限は使いません。
# サーバーが止まったときは、launchd が30秒あけて起動し直します。

set -e
label="${LACIA_LABEL:-jp.imoz.lacia.serve}"
plist="$HOME/Library/LaunchAgents/$label.plist"
target="gui/$(id -u)"

# ほかのものが置いた同じ名前のファイルは、触りません。
ours() { [ ! -e "$plist" ] || grep -q "<string>$label</string>" "$plist"; }

case "$1" in
on)
	lacia="$2"; config="$3"; state="$4"
	[ -x "$lacia" ] && [ -f "$config" ] && [ -n "$state" ] || { echo "先に make install を実行してください。"; exit 1; }
	ours || { echo "$plist は、別のものが置いたファイルのようです。そのままにしました。"; exit 1; }
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
	echo "ログインのときに、サーバーが自動で起動するようにしました。いまも起動しています。"
	echo "  ログ: $state/serve.log"
	echo "  やめるとき: make autostart-off"
	;;
off)
	ours || { echo "$plist は、別のものが置いたファイルのようです。そのままにしました。"; exit 1; }
	launchctl bootout "$target/$label" 2>/dev/null || true
	rm -f "$plist"
	echo "自動の起動をやめて、サーバーを止めました。"
	;;
status)
	if launchctl print "$target/$label" >/dev/null 2>&1; then
		launchctl print "$target/$label" | grep -E '^	(state|pid|last exit code) =' || true
	else
		echo "自動の起動は、登録していません。"
	fi
	;;
*)
	echo "使い方: tools/autostart.sh on <lacia> <設定ファイル> <状態のディレクトリー> | off | status"
	exit 2
	;;
esac
