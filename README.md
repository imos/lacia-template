# レイシアの記録のひな形

レイシアを、自分の Mac で使い始めるためのひな形です。このリポジトリーを複製して、`make install` を実行すると、`lacia` コマンドと設定がそろいます。タスクと記録は、複製したリポジトリーにたまっていきます。

まだ下書きです。

## 必要なもの

- Go（`lacia` を、手元でビルドします）
- Git と、本体（`lacia` のソース）を読める GitHub の認証（`gh auth login` のあと、`gh auth setup-git`）。取得先は `LACIA_SOURCE` にあります。
- Codex か Claude Code の、どちらか

`make install` は、最初にこれらを確かめます。Homebrew が入っていれば、足りない Go と gh を自動で入れます。ログインが要るものと、Codex か Claude Code かの選択は、入れ方を案内して止まります。確かめるだけのときは、`make check` を実行します。

## 始めかた

1. このリポジトリーを、自分の非公開のリポジトリーとして複製します。fork ではなく、複製にしてください。記録には、ほかの人に見せないものが入ります。
2. `make install` を実行します。途中で、レイシアがあなたに呼びかけるときの名前（たとえば「田中さん」）と、予定を読む Google のアカウントを尋ねます。予定を使わないときは、アカウントの欄を空けて進めます。あとから変えるときは、`lacia init` を実行します。
3. Web からの依頼と予約は、Codex があれば Codex へ、なければ Claude Code へ渡します。決めて指定するときは、`make install AGENT=claude` のようにします。
4. `make serve` でサーバーを動かして、`http://127.0.0.1:10148/` を開きます。
5. 予定を読むアカウントを入力したときは、Web の「予定の連携」のページで「Googleで許可する」を押します。求める許可は、予定の読み取りだけです。
6. 別の端末で、`lacia codex` か `lacia claude` を実行すると、レイシアとして会話が始まります。
7. サーバーを、ログインのときに自動で起動したいときは、`make autostart` を実行します。止まったときも、30秒あけて起動し直します。`make serve` とは、同時に動かせません。やめるときは、`make autostart-off` です。ログは `~/.local/state/lacia/serve.log` に出ます。

新しく設定を作ると、毎朝5時から正午までの間に、サーバーの窓口の会話を手が空いたときに新しくします。時刻は記録のタイムゾーンに従います。時間を変えたり自動切り替えを止めたりするときは、`~/.config/lacia/serve.conf` の `window-rollover` を編集します。すでにある設定は、`make install` をやり直しても保ちます。
8. 確認待ちのタスクや会議を Mac の通知で受け取りたいときは、`make notifier` を実行します。Xcode のコマンドライン ツールが要ります。入れなくても使えます。

使い始める前に、[基本の情報と好み](memory/profile.md)と[アカウントの対応](memory/accounts.md)を、ご自分の内容で埋めてください。どちらにも、書く場所の説明と架空の記入例があります。`lacia init` が記憶へ書くのは、空欄の呼び名だけです。使わない項目は消して構いません。

Googleの外部向けOAuthクライアントをテスト中の設定で使う場合、テストユーザーとして登録したアカウントだけが連携でき、許可は7日で切れます。[GoogleのOAuthクライアントの公開状態](https://support.google.com/cloud/answer/15549945?hl=ja)

## 決まった時刻に動かす

Mac 1台で使うときは、予約に宛先を書く必要はありません。予約は、手順3で選んだ Codex または Claude Code で動きます。[定期タスクのひな形](areas/personal/routines/S0001/routine.md)は、`areas/personal/routines/S0001/routine.md` に停止した状態で置いてあります。確かめたい対象と手順を書いて、動かしたいときに `enabled: true` にします。朝8時に動かす場合は、冒頭を次のようにします。

```markdown
---
id: S0001
title: 朝の確認
area: personal
daily: "08:00"
output: matters
conversation: side
enabled: true
---
```

`lacia schedules` で、定期タスクの時刻と有効かどうかを確かめられます。ひな形付属の定期タスクには `S0001` と `S0002` を使います。自分で作る定期タスクは `S1001` から始めます。2件目からは、すべての領域で使っている `S1001` 以降の最大番号に1を足します。ディレクトリー名と定義の `id` には同じ番号を書きます。通常のタスクは `lacia task new` が既定で `T1001` から採番します。

予約の時刻に Mac が眠っていたときは、起きたあとに実行します。眠っていたあいだの回が何回あっても、1回にまとめます。

別の端末で予約を動かすときは、その端末をサーバーへ登録し、会話の宛先を `to: local-codex` のように書きます。端末の登録と通知アプリの設定は、本体のソースの `docs/design/schedules.md` の「実行先を選ぶ」にあります。取得先は `LACIA_SOURCE` にあります。

## 置いてあるもの

| 場所 | 中身 | だれが書くか |
| --- | --- | --- |
| `LACIA_SOURCE` | 本体（`lacia` のソース）の取得先のURL | ひな形の更新で変わります |
| `LACIA_VERSION` | 本体から取得する `lacia` のコミット | ひな形の更新で変わります |
| `AGENTS.md`、`CLAUDE.md` | `lacia rules` を読むように伝える、数行の案内 | 書き換えません |
| `rules/local.md` | このリポジトリーだけの決まり | 自分とレイシア |
| `.lacia/config.json` | 領域と、ご本人の呼び名 | 自分 |
| `.lacia/serve.conf` | 画面や伝言で使うプロファイルの名前と、予定の連携 | 自分 |
| `.lacia/calendars.json` | 予定を読むカレンダーの一覧 | `lacia init` と自分 |
| `memory/` | 基本の情報、アカウントの対応、いまの状況 | 自分とレイシア |
| `tools/` | `make` が使うスクリプト | 書き換えません |
| `areas/<領域>/routines/` | 決まった時刻に動かす仕事 | 自分とレイシア |
| `areas/work/`、`areas/personal/` | 領域ごとの、タスク（`tasks/`）、プロジェクト（`projects/`）、知識（`knowledge/`）、手順（`procedures/`） | レイシアと自分 |

共通の決まりは、`lacia` の実行ファイルに入っています。`lacia rules` で読めます。文章の書き方は `lacia rules writing` に、話し方と返事の例は `lacia rules voice` にあります。レイシア自身のものの見方や好みは、[わたしのこと](memory/self.md)で読めます。

共通の決まりを変えたいときは、`rules/<名前>.md` に同じ名前の文書を置くと、そちらが使われます。節を足すだけのときは、`rules/<名前>.local.md` に書くと、同じ名前の文書の最後に足されます。

Macで使う場合は、定期タスク（S0002）で `local/` の点検が毎日10:00に動きます。詳しい判断の条件は[片づける手順](areas/personal/procedures/local-storage.md)にあります。容量の上限はリポジトリーごとに10 GiBで、`.lacia/local-storage.json` の `limit_gib` で変えられます。上限を超えるときだけ要確認にし、それ以下は実行結果に記録します。点検にはPython 3を使います。Mac以外のサーバーで使う場合は、この予約の実行先をMacへ設定してから有効にしてください。

記録の形は、`lacia doctor` で点検できます。直さずに、誤りとお知らせを出します。

## 更新

ひな形が新しくなったら、取り込んで、`make install` をやり直します。

```sh
git remote add template <ひな形のアドレス>   # 最初の1回だけ
git pull template main
make install
```

両方で同じファイルを変更していると、取り込みが衝突することがあります。手元の記録や設定を残して、ひな形で変わった箇所を取り込んでください。

旧番号の `S1001` や `S1016` をすでに運用している場合は、その定期タスクの番号と履歴を保ちます。取り込み後に番号を変えた同じ定期タスクが増えた場合は、前から運用しているほうを使います。

設定の `format` が1のままなら、対応する `lacia` を入れてから、サーバーを止めた状態で `lacia migrate --dry-run` を実行します。固定IDと移動先を確かめ、`lacia migrate` で領域の下へ移します。移行後に `lacia schedules` と `lacia doctor --links` を確かめます。詳しい手順は、本体のソースの `docs/design/records.md` の「形を移す（`lacia migrate`）」にあります。

## ライセンス

このひな形は[MITライセンス](LICENSE)で利用できます。
