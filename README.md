# レイシアの記録のひな形

レイシアを、自分の Mac で使い始めるためのひな形です。このリポジトリーを複製して、`make install` を実行すると、`lacia` コマンドと設定がそろいます。タスクと記録は、複製したリポジトリーにたまっていきます。

まだ下書きです。ログインのときの自動の起動は、入っていません。サーバーは、`make serve` で動かしているあいだだけ動きます。

## 必要なもの

- Go（`lacia` をビルドします）
- Git と、`imos/lacia` を読める GitHub の認証（`gh auth login` のあと、`gh auth setup-git`）
- Codex か Claude Code の、どちらか

## 始めかた

1. このリポジトリーを、自分の非公開のリポジトリーとして複製します。fork ではなく、複製にしてください。記録には、ほかの人に見せないものが入ります。
2. `make install` を実行します。途中で、レイシアに呼んでほしい名前（たとえば「田中さん」）を尋ねます。あとから変えるときは、`lacia init` を実行します。
3. Web からの依頼と予約は、Codex があれば Codex へ、なければ Claude Code へ渡します。決めて指定するときは、`make install AGENT=claude` のようにします。
4. `make serve` でサーバーを動かして、`http://127.0.0.1:10148/` を開きます。
5. 別の端末で、`lacia codex` か `lacia claude` を実行すると、レイシアとして会話が始まります。
6. 確認待ちのタスクや会議を Mac の通知で受け取りたいときは、`make notifier` を実行します。Xcode のコマンドライン ツールが要ります。入れなくても使えます。

予約の時刻に Mac が眠っていたときは、起きたあとに実行します。眠っていたあいだの回が何回あっても、1回にまとめます。

## 置いてあるもの

| 場所 | 中身 | だれが書くか |
| --- | --- | --- |
| `LACIA_VERSION` | 使う `lacia` の版 | ひな形の更新で変わります |
| `AGENTS.md`、`CLAUDE.md` | `lacia rules` を読むように伝える、数行の案内 | 書き換えません |
| `rules/local.md` | このリポジトリーだけの決まり | 自分とレイシア |
| `.lacia/config.json` | 領域と、呼び名 | 自分 |
| `.lacia/serve.conf` | 表示の名前、予定の連携 | 自分 |
| `memory/` | 基本の情報、アカウントの対応、いまの状況 | 自分とレイシア |
| `schedules/` | 決まった時刻に動かす仕事 | 自分とレイシア |
| `work/tasks/`、`personal/tasks/` | タスク | レイシア |

共通の決まりは、`lacia` の実行ファイルに入っています。`lacia rules` で読めます。変えたいときは、`rules/<名前>.md` に同じ名前の文書を置くと、そちらが使われます。

## 更新

ひな形が新しくなったら、取り込んで、`make install` をやり直します。

```sh
git remote add template <ひな形のアドレス>   # 最初の1回だけ
git pull template main
make install
```

`AGENTS.md`、`Makefile`、`LACIA_VERSION` を書き換えていなければ、取り込みは衝突しません。
