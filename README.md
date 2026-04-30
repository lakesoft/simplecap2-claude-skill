# SimpleCap2 × Claude Code Skill

> Drive [SimpleCap2](https://apps.apple.com/app/simplecap2/) (a macOS screen
> capture app) and search its gallery by Finder color tag from
> [Claude Code](https://www.claude.com/product/claude-code).

> ⚠️ **This repository is distribution-only.** Issues are disabled and
> external pull requests are auto-closed. The skill is published here for
> install via `/plugin marketplace add`; development happens privately.

> 🇯🇵 日本語版は英語の下にあります.

---

## English

### What this skill lets Claude do

- **Take an interactive screenshot for me**
  > "Capture this region of my screen and tell me what's wrong" — Claude
  > triggers SimpleCap2's region/window selection. You drag the area you
  > want, hit Save, and Claude reads the resulting image and continues.

- **Search my screenshot archive by Finder color tag**
  > "Make a Markdown report from my Red-tagged screenshots" — Claude lists
  > captures matching the color tag, reads the relevant images, and
  > produces output. Tag colors are accepted in English, by Finder label
  > number (1–7), or in the localized Finder name (Japanese, French, etc.).

### Prerequisites

- macOS 15 (Sequoia) or later.
- [SimpleCap2](https://apps.apple.com/app/simplecap2/) 1.0.0 build 42 or
  later, installed and with a save folder configured.
- Claude Code with plugin support.

### Install

```text
/plugin marketplace add lakesoft/simplecap2-claude-skill
/plugin install simplecap2@simplecap2
```

That's it. The plugin is now available in the current Claude Code session;
new sessions will load it automatically.

### Update

```text
/plugin marketplace update simplecap2
/plugin update simplecap2@simplecap2
```

### Uninstall

```text
/plugin uninstall simplecap2@simplecap2
/plugin marketplace remove simplecap2
```

### How it works

This plugin is a thin Bash layer on top of SimpleCap2's own
URL scheme (`simplecap2://capture/{region|window}`) and read-only CLI
arguments (`--version`, `--print-folder`, `--list-captures`). The CLI
codepath inside SimpleCap2 imports only Foundation, so it never triggers
TCC permission prompts (Screen Recording, AppleEvents, Accessibility).

For interactive captures, completion is detected by polling the save
folder for new image files (mtime > start). The user always sees a red
"external trigger" indicator inside SimpleCap2 while a request is
outstanding, so it's never silent.

Each script verifies SimpleCap2's code signature against the Lakesoft
Apple Developer Team ID (`EDF37AMEEW`) before running. A tampered binary
or a same-bundle-id imposter app will be rejected with a clear error.

### Privacy

Captures may contain credentials, internal company info, personal
correspondence, etc. Even tag-filtered queries can return images you
didn't intend to share. The skill's prompt (`SKILL.md`) instructs Claude
to confirm before quoting/summarising publicly and to drop image
references from the conversation when no longer needed, but the
ultimate responsibility is yours.

This skill performs **no network access**, sends **no telemetry**, and
talks only to your locally installed SimpleCap2 process.

### Known limits

- Cancel detection is timing-based, not signal-based. If the user takes
  longer than the timeout to make a selection, the script exits as if
  cancelled. Override `SIMPLECAP_TIMEOUT` (default 60 s) for slow flows.
- Concurrent `simplecap-capture` calls in the same save folder will
  confuse each other. Run captures sequentially.
- Only `region` and `window` capture modes are exposed. Whole-display
  captures and other SimpleCap2 features remain GUI-only for now.

### Repository layout

```
.
├── .claude-plugin/
│   ├── marketplace.json    # Catalog metadata (read by /plugin marketplace add)
│   └── plugin.json         # Plugin manifest
└── plugins/
    └── simplecap2/
        ├── .claude-plugin/
        │   └── plugin.json
        ├── bin/
        │   ├── _lib.sh         # Shared helpers (Team ID verification, app discovery)
        │   ├── simplecap-version
        │   ├── simplecap-folder
        │   ├── simplecap-list
        │   └── simplecap-capture
        └── skills/
            └── simplecap2/
                └── SKILL.md    # Skill prompt loaded by Claude Code
```

### Development

Local-test before publishing:

```bash
/plugin marketplace add /absolute/path/to/this/checkout
/plugin install simplecap2@simplecap2
```

Set `SIMPLECAP2_APP_PATH=/path/to/SimpleCap2.app` to point the bin
scripts at a non-standard install location (e.g. an Xcode archive build).

### License

MIT.

---

## 日本語

> ⚠️ **本リポジトリは配布専用です。** Issue は無効化されており、外部からの Pull Request は自動クローズされます。`/plugin marketplace add` でのインストール用に公開しているもので、開発は非公開で行っています。

### このスキルでできること

- **対話的にスクショを撮らせる**
  > 「画面のこの範囲をキャプチャして、何が問題か説明して」と頼むと、SimpleCap2 の範囲選択／ウィンドウ選択が立ち上がります。ドラッグして保存ボタンを押せば、Claude が結果画像を読み込んで処理を続けます。

- **過去のキャプチャを Finder カラータグで検索する**
  > 「Red タグの画像で Markdown レポート作って」と頼むと、Claude が該当する画像を一覧化し、必要な分だけ読んでまとめます。色名は英語・ラベル番号 1〜7・各国 Finder 名（日本語・仏語・独語・西語・伊語・韓語・中文・葡語・露語）すべて受け付けます。

### 前提条件

- macOS 15 (Sequoia) 以降
- [SimpleCap2](https://apps.apple.com/app/simplecap2/) 1.0.0 build 42 以降がインストール済み、保存先フォルダを設定済み
- Claude Code（プラグイン機能対応版）

### インストール

```text
/plugin marketplace add lakesoft/simplecap2-claude-skill
/plugin install simplecap2@simplecap2
```

これだけです。現在のセッションに即時反映され、以降の新セッションでも自動でロードされます。

### 更新

```text
/plugin marketplace update simplecap2
/plugin update simplecap2@simplecap2
```

### アンインストール

```text
/plugin uninstall simplecap2@simplecap2
/plugin marketplace remove simplecap2
```

### 仕組み

SimpleCap2 自体が公開している URL Scheme（`simplecap2://capture/{region|window}`）と読み取り専用 CLI 引数（`--version`、`--print-folder`、`--list-captures`）の薄いラッパーです。SimpleCap2 の CLI コードパスは Foundation のみを import しているため、TCC 権限要求（画面収録・AppleEvents・アクセシビリティ）が誤発火することはありません。

対話キャプチャの完了検知は保存フォルダの mtime ポーリング（開始時刻より新しい画像ファイルを探す）で行います。実行中は SimpleCap2 のタイトルバーとオーバーレイに赤い「外部要求中」インジケーターが出るので、Claude が起動したことが必ずユーザに見える形になっています。

各スクリプトは実行前に SimpleCap2 のコード署名を検証し、Lakesoft の Apple Developer Team ID（`EDF37AMEEW`）と一致しないバイナリは拒否します。改ざんされた SimpleCap2 や、同じ bundle ID を名乗る偽アプリからのリクエストは通りません。

### プライバシー

スクリーンショットには認証情報・社内情報・個人的なやり取り等が映り込みえます。タグでフィルタした検索結果でも、ユーザが意図せずタグを付けた機密画像が混じる可能性はあります。スキルの `SKILL.md` には「公開／要約前にユーザに確認すること」「不要な画像参照は会話履歴から外すこと」を Claude に指示してありますが、最終責任はユーザにあります。

本スキルは **ネットワーク通信を一切行いません**。テレメトリ送信もなく、ローカルにインストールされた SimpleCap2 プロセスとのみやり取りします。

### 既知の制約

- キャンセル検知はタイミングベースで、シグナルベースではありません。タイムアウト（デフォルト 60 秒）より長く選択操作にかかると、キャンセルしたのと同じ扱いになります。`SIMPLECAP_TIMEOUT` 環境変数で上書き可能
- 同じ保存フォルダで `simplecap-capture` を並行実行すると mtime 検知が混線します。セッション内では 1 リクエストずつ
- 範囲選択（region）とウィンドウキャプチャ（window）のみ公開しています。ディスプレイ全体キャプチャ等は GUI からのみ利用できます

### リポジトリ構成

```
.
├── .claude-plugin/
│   ├── marketplace.json    # /plugin marketplace add が読むカタログ情報
│   └── plugin.json         # プラグインのマニフェスト
└── plugins/
    └── simplecap2/
        ├── .claude-plugin/
        │   └── plugin.json
        ├── bin/
        │   ├── _lib.sh         # 共通ヘルパー（Team ID 検証、アプリ検出）
        │   ├── simplecap-version
        │   ├── simplecap-folder
        │   ├── simplecap-list
        │   └── simplecap-capture
        └── skills/
            └── simplecap2/
                └── SKILL.md    # Claude Code が読み込むスキルプロンプト
```

### 開発

ローカルでテストする：

```bash
/plugin marketplace add /absolute/path/to/this/checkout
/plugin install simplecap2@simplecap2
```

`SIMPLECAP2_APP_PATH=/path/to/SimpleCap2.app` を設定すると、bin スクリプトの参照先を非標準の場所（Xcode の archive ビルド等）に変更できます。

### ライセンス

MIT。
