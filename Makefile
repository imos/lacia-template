# この記録のリポジトリーでレイシアを使うためのコマンドです。
#
#   make install                      LACIA_VERSION で指定した版を LACIA_SOURCE から取得してビルドし、設定を作ります
#   make check                        必要なものがそろっているかを確かめます
#   make install LACIA_SRC=../lacia   手元で編集したソースからビルドします
#   make serve                        サーバーを動かします（http://127.0.0.1:10148/）
#   make notifier                     Mac の通知アプリを入れます（Xcode のコマンドライン ツールが要ります）
#   make autostart                    ログインのときに、サーバーが自動で起動するようにします
#   make autostart-off                サーバーの自動起動をやめます
#   make uninstall                    インストールした lacia とサーバーの設定を削除します

PREFIX ?= $(HOME)/.local
CONFIG ?= $(HOME)/.config/lacia/serve.conf
STATE  ?= $(HOME)/.local/state/lacia
# Webからの依頼と定期タスクは、CodexがあればCodexに、なければClaude Codeに渡します。
# 初期設定でClaude Codeを選ぶには、make install AGENT=claude を実行してください。
AGENT  ?= $(shell command -v codex >/dev/null 2>&1 && echo codex || echo claude)
# 通知アプリが接続するサーバーのアドレスです。
URL    ?= http://127.0.0.1:10148
LACIA  := $(PREFIX)/bin/lacia
ROOT   := $(CURDIR)
VERSION := $(shell cat LACIA_VERSION)

.PHONY: install check prepare binary config serve notifier autostart autostart-off uninstall

install: prepare binary config
	@if grep -q '"オーナーさん"' .lacia/config.json && [ -t 0 ]; then $(LACIA) init; fi
	@echo
	@echo "lacia をインストールしました。PATH に $(PREFIX)/bin が含まれていることを確かめてください。"
	@echo "  make serve     サーバーを起動します。そのあと、ブラウザーで http://127.0.0.1:10148/ を開いてください。"
	@echo "  lacia codex    Codexでわたしと会話できます。"
	@echo "  lacia claude   Claude Codeでわたしと会話できます。"
	@echo "  make notifier  タスクや会議の通知を受け取りたいときに、Macの通知アプリを入れます。"
	@echo "  make autostart ログイン時にサーバーを自動で起動するようにします。"

# Homebrewがあれば、足りないGoや、GitHubの認証に必要なghをインストールします。
prepare:
	@PREFIX="$(PREFIX)" LACIA_SRC="$(LACIA_SRC)" tools/prepare.sh

check:
	@PREFIX="$(PREFIX)" LACIA_SRC="$(LACIA_SRC)" tools/prepare.sh --check

binary: prepare
	@mkdir -p $(PREFIX)/bin
ifdef LACIA_SRC
	cd $(LACIA_SRC) && go build -o $(LACIA) ./cmd/lacia
else
	@set -eu; \
	build=$$(mktemp -d); \
	trap 'rm -rf "$$build"' 0; \
	out=$$(cd "$(PREFIX)/bin" && pwd)/lacia; \
	tools/checkout-source.sh checkout "$$build/source" "$(VERSION)"; \
	cd "$$build/source" && go build -o "$$out" ./cmd/lacia
endif
	@$(LACIA) rules list >/dev/null

# 待ち受けるアドレスや、起動するコマンドは、リポジトリーの外に置きます。
# すでにあるファイルは、書き換えません。
config:
	@mkdir -p $(dir $(CONFIG)) $(STATE)
	@if [ -e $(CONFIG) ]; then \
		echo "既存の設定 $(CONFIG) を使います。"; \
	else \
		printf 'root = %s\nstate = %s\n%s = %s\ngit-sync = true\nwindow-rollover = 05:00-12:00\n' "$(ROOT)" "$(STATE)" "$(AGENT)" "$(AGENT)" > $(CONFIG); \
		echo "$(CONFIG) を作りました。"; \
	fi

serve:
	$(LACIA) serve --config $(CONFIG)

# 通知アプリはメニューバーに常駐し、確認待ちのタスクと会議を知らせます。
# すでにインストールしてあるときは、既存のアプリと設定を保って止まります。
notifier:
	@set -eu; \
	src="$(LACIA_SRC)"; \
	build=$$(mktemp -d); \
	trap 'rm -rf "$$build"' 0; \
	if [ -z "$$src" ]; then \
		src="$$build/source"; \
		tools/checkout-source.sh checkout "$$src" "$(VERSION)"; \
	fi; \
	python3 "$$src/macos/notifier/manage.py" build "$$build/Lacia Notifications.app" && \
	python3 "$$src/macos/notifier/manage.py" install "$$build/Lacia Notifications.app" --lacia "$(LACIA)" --url "$(URL)" && \
	python3 "$$src/macos/notifier/manage.py" start
	@echo "通知アプリを入れました。macOS が通知の許可を尋ねたら、許可してください。"
	@echo "通知アプリを削除するときは、本体のソースで python3 macos/notifier/manage.py uninstall を実行してください。"

# make serve と同時には動かせません。同じアドレスで待ち受けるためです。
autostart:
	@tools/autostart.sh on "$(LACIA)" "$(CONFIG)" "$(STATE)"

autostart-off:
	@tools/autostart.sh off

uninstall:
	@tools/autostart.sh off >/dev/null 2>&1 || true
	rm -f $(LACIA) $(CONFIG)
	@echo "記録は $(ROOT) に、サーバーの状態は $(STATE) に残っています。"
