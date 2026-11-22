# レイシアを、この記録のリポジトリーで使えるようにします。
#
#   make install                      要るものを確かめ、LACIA_VERSION の版の lacia をビルドして、設定を作ります
#   make check                        要るものがそろっているかを、確かめるだけです
#   make install LACIA_SRC=../lacia   手元のソースからビルドします（コードを直したい方へ）
#   make serve                        サーバーを動かします（http://127.0.0.1:10148/）
#   make notifier                     Mac の通知アプリを入れます（Xcode のコマンドライン ツールが要ります）
#   make autostart                    ログインのときに、サーバーが自動で起動するようにします
#   make autostart-off                自動の起動をやめます
#   make uninstall                    入れた lacia と設定を消します（記録は消しません）

PREFIX ?= $(HOME)/.local
CONFIG ?= $(HOME)/.config/lacia/serve.conf
STATE  ?= $(HOME)/.local/state/lacia
# 依頼を渡す先です。Codex があれば Codex、なければ Claude Code を使います。
# 決めて指定するときは、make install AGENT=claude のようにします。
AGENT  ?= $(shell command -v codex >/dev/null 2>&1 && echo codex || echo claude)
# 通知アプリがつなぐ、サーバーのアドレスです。
URL    ?= http://127.0.0.1:10148
LACIA  := $(PREFIX)/bin/lacia
ROOT   := $(CURDIR)
VERSION := $(shell cat LACIA_VERSION)

.PHONY: install check prepare binary config serve notifier autostart autostart-off uninstall

install: prepare binary config
	@if grep -q '"オーナーさん"' .lacia/config.json && [ -t 0 ]; then $(LACIA) init; fi
	@echo
	@echo "入りました。$(PREFIX)/bin が PATH にあることを確かめてください。"
	@echo "  make serve     サーバーを動かして、http://127.0.0.1:10148/ を開きます"
	@echo "  lacia codex    Codex を、レイシアとして起動します"
	@echo "  lacia claude   Claude Code を、レイシアとして起動します"
	@echo "  make notifier  Mac の通知アプリを入れます（入れなくても使えます）"
	@echo "  make autostart ログインのときに、サーバーが自動で起動するようにします"

# 足りないものは、Homebrew があれば入れます。入れるのは Go と gh だけです。
prepare:
	@PREFIX="$(PREFIX)" LACIA_SRC="$(LACIA_SRC)" tools/prepare.sh

check:
	@PREFIX="$(PREFIX)" LACIA_SRC="$(LACIA_SRC)" tools/prepare.sh --check

binary: prepare
	@mkdir -p $(PREFIX)/bin
ifdef LACIA_SRC
	cd $(LACIA_SRC) && go build -o $(LACIA) ./cmd/lacia
else
	GOPRIVATE=github.com/imos GOBIN=$(PREFIX)/bin go install github.com/imos/lacia/cmd/lacia@$(VERSION)
endif
	@$(LACIA) rules list >/dev/null

# 待ち受けるアドレスや、起動するコマンドは、リポジトリーの外に置きます。
# すでにあるファイルは、書き換えません。
config:
	@mkdir -p $(dir $(CONFIG)) $(STATE)
	@if [ -e $(CONFIG) ]; then \
		echo "$(CONFIG) は、すでにあるので、そのままにしました。"; \
	else \
		printf 'root = %s\nstate = %s\n%s = %s\ngit-sync = true\n' "$(ROOT)" "$(STATE)" "$(AGENT)" "$(AGENT)" > $(CONFIG); \
		echo "$(CONFIG) を作りました。"; \
	fi

serve:
	$(LACIA) serve --config $(CONFIG)

# 通知アプリは、メニューバーに常駐して、確認待ちのタスクと会議を知らせます。
# すでに入っているときは、何も変えずに止まります。
notifier:
	@src="$(LACIA_SRC)"; \
	if [ -z "$$src" ]; then \
		src=$$(GOPRIVATE=github.com/imos go mod download -json github.com/imos/lacia@$(VERSION) | sed -n 's/.*"Dir": "\(.*\)".*/\1/p'); \
	fi; \
	build=$$(mktemp -d) && \
	python3 "$$src/macos/notifier/manage.py" build "$$build/Lacia Notifications.app" && \
	python3 "$$src/macos/notifier/manage.py" install "$$build/Lacia Notifications.app" --lacia "$(LACIA)" --url "$(URL)" && \
	python3 "$$src/macos/notifier/manage.py" start
	@echo "通知アプリを入れました。macOS が通知の許可を尋ねたら、許可してください。"
	@echo "外すときは、lacia のソースの macos/notifier/manage.py uninstall を使います。"

# make serve と同時には動かせません。同じアドレスで待ち受けるためです。
autostart:
	@tools/autostart.sh on "$(LACIA)" "$(CONFIG)" "$(STATE)"

autostart-off:
	@tools/autostart.sh off

uninstall:
	@tools/autostart.sh off >/dev/null 2>&1 || true
	rm -f $(LACIA) $(CONFIG)
	@echo "記録（$(ROOT)）と、状態（$(STATE)）は、残してあります。"
