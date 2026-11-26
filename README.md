# レイシアの記録のひな形

レイシアを、自分の Mac で使い始めるためのひな形です。このリポジトリーを複製して、`make install` を実行すると、`lacia` コマンドと設定がそろいます。タスクと記録は、複製したリポジトリーにたまっていきます。

まだ下書きです。

## 必要なもの

- Go（`lacia` を、手元でビルドします）
- Git と、`imos/lacia` を読める GitHub の認証（`gh auth login` のあと、`gh auth setup-git`）
- Codex か Claude Code の、どちらか

`make install` は、最初にこれらを確かめます。Homebrew が入っていれば、足りない Go と gh を自動で入れます。ログインが要るものと、Codex か Claude Code かの選択は、入れ方を案内して止まります。確かめるだけのときは、`make check` を実行します。

## 始めかた

1. このリポジトリーを、自分の非公開のリポジトリーとして複製します。fork ではなく、複製にしてください。記録には、ほかの人に見せないものが入ります。
2. `make install` を実行します。途中で、レイシアに呼んでほしい名前（たとえば「田中さん」）と、予定を読む Google のアカウントを尋ねます。予定を使わないときは、何も入力せずに進めます。あとから変えるときは、`lacia init` を実行します。
3. Web からの依頼と予約は、Codex があれば Codex へ、なければ Claude Code へ渡します。決めて指定するときは、`make install AGENT=claude` のようにします。
4. `make serve` でサーバーを動かして、`http://127.0.0.1:10148/` を開きます。
5. 予定を読むアカウントを入力したときは、Web の「予定の連携」のページで「Googleで許可する」を押します。求める許可は、予定の読み取りだけです。
6. 別の端末で、`lacia codex` か `lacia claude` を実行すると、レイシアとして会話が始まります。
7. サーバーを、ログインのときに自動で起動したいときは、`make autostart` を実行します。止まったときも、30秒あけて起動し直します。`make serve` とは、同時に動かせません。やめるときは、`make autostart-off` です。ログは `~/.local/state/lacia/serve.log` に出ます。
8. 確認待ちのタスクや会議を Mac の通知で受け取りたいときは、`make notifier` を実行します。Xcode のコマンドライン ツールが要ります。入れなくても使えます。

使い始める前に、[基本の情報と好み](memory/profile.md)と[アカウントの対応](memory/accounts.md)を、ご自分の内容で埋めてください。どちらにも、書く場所の説明と架空の記入例があります。`lacia init` が記憶へ書くのは、空欄の呼び名だけです。使わない項目は消して構いません。

## 決まった時刻に動かす

Mac 1台で使うときは、予約に宛先を書く必要はありません。予約は、手順3で選んだ Codex または Claude Code で動きます。`schedules/` に、たとえば次のような内容で `morning.md` を置きます。

```markdown
---
title: 朝の確認
daily: "08:00"
conversation: side
---

きょうの予定を確認し、予定があるときだけ短く知らせてください。
```

予約の時刻に Mac が眠っていたときは、起きたあとに実行します。眠っていたあいだの回が何回あっても、1回にまとめます。

別の端末で予約を動かすときは、その端末をサーバーへ登録し、会話の宛先を `to: local-codex` のように書きます。端末の登録と通知アプリの設定は、[予約の説明](https://github.com/imos/lacia/blob/main/docs/design/schedules.md#実行先を選ぶ)にあります。

## 置いてあるもの

| 場所 | 中身 | だれが書くか |
| --- | --- | --- |
| `LACIA_VERSION` | 使う `lacia` の版 | ひな形の更新で変わります |
| `AGENTS.md`、`CLAUDE.md` | `lacia rules` を読むように伝える、数行の案内 | 書き換えません |
| `rules/local.md` | このリポジトリーだけの決まり | 自分とレイシア |
| `.lacia/config.json` | 領域と、呼び名 | 自分 |
| `.lacia/serve.conf` | 表示の名前、予定の連携 | 自分 |
| `.lacia/calendars.json` | 予定を読むカレンダーの一覧 | `lacia init` と自分 |
| `memory/` | 基本の情報、アカウントの対応、いまの状況 | 自分とレイシア |
| `tools/` | `make` が使うスクリプト | 書き換えません |
| `routines/` | 決まった時刻に動かす仕事 | 自分とレイシア |
| `areas/work/`、`areas/personal/` | 領域ごとの、タスク（`tasks/`）、プロジェクト（`projects/`）、知識（`knowledge/`）、手順（`procedures/`） | レイシアと自分 |

共通の決まりは、`lacia` の実行ファイルに入っています。`lacia rules` で読めます。変えたいときは、`rules/<名前>.md` に同じ名前の文書を置くと、そちらが使われます。節を足すだけのときは、`rules/<名前>.local.md` に書くと、同じ名前の文書の最後に足されます。

Macで使う場合は、定期タスク（S1016）で `local/` の点検が毎日10:00に動きます。詳しい判断の条件は[片づける手順](areas/personal/procedures/local-storage.md)にあります。容量の上限はリポジトリーごとに10 GiBで、`.lacia/local-storage.json` の `limit_gib` で変えられます。上限を超えるときだけ要確認にし、それ以下は実行結果に記録します。点検にはPython 3を使います。Mac以外のサーバーで使う場合は、この予約の実行先をMacへ設定してから有効にしてください。

記録の形は、`lacia doctor` で点検できます。直さずに、誤りとお知らせを出します。

## 更新

ひな形が新しくなったら、取り込んで、`make install` をやり直します。

```sh
git remote add template <ひな形のアドレス>   # 最初の1回だけ
git pull template main
make install
```

`AGENTS.md`、`Makefile`、`LACIA_VERSION` を書き換えていなければ、取り込みは衝突しません。

## ライセンス

このひな形は[MITライセンス](LICENSE)で利用できます。
