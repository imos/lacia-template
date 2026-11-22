# レイシアを、この記録のリポジトリーで使えるようにします。
#
#   make install                      LACIA_VERSION の版の lacia を入れて、設定を作ります
#   make install LACIA_SRC=../lacia   手元のソースからビルドします（コードを直したい方へ）
#   make serve                        サーバーを動かします（http://127.0.0.1:10148/）
#   make uninstall                    入れた lacia と設定を消します（記録は消しません）

PREFIX ?= $(HOME)/.local
CONFIG ?= $(HOME)/.config/lacia/serve.conf
STATE  ?= $(HOME)/.local/state/lacia
# 依頼を渡す先です。Codex があれば Codex、なければ Claude Code を使います。
# 決めて指定するときは、make install AGENT=claude のようにします。
AGENT  ?= $(shell command -v codex >/dev/null 2>&1 && echo codex || echo claude)
LACIA  := $(PREFIX)/bin/lacia
ROOT   := $(CURDIR)
VERSION := $(shell cat LACIA_VERSION)

.PHONY: install binary config serve uninstall

install: binary config
	@echo
	@echo "入りました。$(PREFIX)/bin が PATH にあることを確かめてください。"
	@echo "  make serve     サーバーを動かして、http://127.0.0.1:10148/ を開きます"
	@echo "  lacia codex    Codex を、レイシアとして起動します"
	@echo "  lacia claude   Claude Code を、レイシアとして起動します"

binary:
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

uninstall:
	rm -f $(LACIA) $(CONFIG)
	@echo "記録（$(ROOT)）と、状態（$(STATE)）は、残してあります。"
