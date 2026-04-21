# Claude Plugins Monorepo

Claude Code 用プラグイン（skills, hooks, rules）の開発リポジトリ。

## よく使うコマンド

```bash
# ローカルでプラグインをテスト
claude --plugin-dir ./packages/<plugin>

# セッション中にプラグインの変更を反映
/reload-plugins

# マーケットプレイスの検証
claude plugin validate .

# assets/ 内のシェルスクリプト構文チェック
bash -n packages/<plugin>/skills/<skill-name>/assets/<name>.sh

# SKILL.md frontmatter 確認
head -5 packages/<plugin>/skills/<skill-name>/SKILL.md

# リリース（plugin.json のバージョンバンプ + タグ + リリース PR）
/auto-release
```

## リポジトリ構造

```
.claude-plugin/
  marketplace.json               # マーケットプレイスカタログ（プラグイン一覧）
packages/
  mjc-git-workflow/              # Git ワークフロー系プラグイン
    .claude-plugin/
      plugin.json                # プラグインマニフェスト（name, version 等）
    skills/
      smart-commit/              # 差分を作業単位で分割コミット
      smart-pr/                  # PR 作成・更新の自動化
      smart-git-sync/            # ブランチ同期・整理
      smart-issue-resolve/       # Issue からブランチ作成〜実装
      smart-issue-plan/          # Issue の実装計画を作成・更新
      smart-review/              # ローカル変更のセルフレビュー
      smart-review-apply/        # レビューフィードバックの適用
    README.md
  mjc-claude-skill-tool/           # スキル品質改善・環境構成レビューツール
    .claude-plugin/
      plugin.json
    skills/
      skill-improver/              # skill-creator 連携 + コンテキスト管理・静的チェック
      empirical-prompt-tuning/     # 新規 subagent 実行でプロンプト・skill を反復チューニング
      claude-code-update-review/   # Claude Code バージョンアップ後の構成レビュー
    README.md
.claude/
  rules/                         # プロジェクト共通ルール（Git 規約など）
  skills/
    auto-release/                # バージョン更新・タグ付け・リリース（プロジェクトローカル）
```

## プラグイン構造

### マニフェスト

各プラグインは `.claude-plugin/plugin.json` が必須。**`plugin.json` のみ** `.claude-plugin/` 内に配置。他のディレクトリ（`skills/`, `hooks/` 等）はプラグインルートに置く。

```json
{
  "name": "my-plugin",
  "description": "プラグインの説明",
  "version": "1.0.0",
  "author": { "name": "author-name" }
}
```

`version` と個別プラグインの `description` は `plugin.json` で管理する（`marketplace.json` との重複を避けるため、`marketplace.json` のプラグインエントリには `name` + `source` のみ記載する）。

### プラグインのディレクトリ構成

```
<plugin-name>/
  .claude-plugin/
    plugin.json    # マニフェスト（必須）
  skills/          # スキル定義（SKILL.md）
  agents/          # カスタムエージェント定義
  hooks/           # hooks.json でイベントハンドラー
  commands/        # Markdown ベースのコマンド
  .mcp.json        # MCP サーバー設定
  .lsp.json        # LSP サーバー設定
  settings.json    # プラグイン有効時のデフォルト設定
  README.md
```

必要なサブディレクトリだけ配置する。

本 monorepo では user-invocable な機能も `commands/` ではなく `skills/` に統一する（`disable-model-invocation: true` を付けた Skill として追加する）。frontmatter・引数パース・コンテキスト管理の規約を揃えるため。

### マーケットプレイスカタログ

`.claude-plugin/marketplace.json` はプラグインの一覧と取得元を定義する。各プラグインエントリには `name` + `source` が最低限必要。

```json
{
  "name": "marketplace-name",
  "description": "マーケットプレイスの説明",
  "owner": { "name": "owner-name" },
  "plugins": [
    { "name": "plugin-name", "source": "./packages/plugin-name" }
  ]
}
```

### 配布・インストール

```bash
# marketplace として登録
/plugin marketplace add mjcreativelab/mjcreativelab-claude-plugins

# プラグインをインストール
/plugin install <plugin-name>@mjcreativelab-claude-plugins
```

### キャッシュの注意

プラグインはインストール時にキャッシュディレクトリにコピーされる。プラグインディレクトリ外のファイル（`../shared-utils` 等）はコピーされないため参照不可。ファイル共有が必要な場合はシンボリックリンクを使用する。

hooks や MCP 設定でプラグイン内のファイルを参照するには `${CLAUDE_PLUGIN_ROOT}` を使用する（スキル内の `${CLAUDE_SKILL_DIR}` とは別物）。

## スキルファイル形式

### ディレクトリ構造

プロジェクトローカルスキル（`.claude/skills/`）もプラグインスキルも `<name>/SKILL.md` のディレクトリ構造が必須（フラットファイル配置では認識されない）。

```
<skill-name>/
├── SKILL.md          # メイン指示（必須・500行以下推奨）
├── assets/           # テンプレート・スクリプト（出力物の雛形、実行スクリプト）
└── references/       # 参照表・定義（対応表、ルール表など読み取り専用の情報）
```

SKILL.md からサポートファイルを参照して、Claude が必要な時だけ読み込むようにする:

```markdown
GitMoji と type の対応: [references/gitmoji-types.md](references/gitmoji-types.md)
```

### frontmatter

```yaml
---
name: my-skill                    # kebab-case、省略時はディレクトリ名
description: スキルの説明           # 推奨。Claude が自動読み込みの判断に使用
argument-hint: "[issue-number]"    # オートコンプリートに表示するヒント
disable-model-invocation: true     # true → ユーザーの /name でのみ起動（副作用のあるスキル向け）
user-invocable: false              # false → / メニュー非表示（バックグラウンド知識向け）
allowed-tools: Read, Grep, Glob    # スキル実行中に許可なしで使えるツール
context: fork                      # fork → サブエージェントで実行（メイン会話と分離）
agent: Explore                     # context: fork 時のサブエージェントタイプ
---
```

`name` + `description` は必ず記載する。他はスキルの性質に応じて使用。

> `context`, `agent`, `user-invocable` は Claude Code プラットフォームの機能。本リポジトリでは未使用だがリファレンスとして記載。

### 文字列置換

SKILL.md 内で使用できる変数:

| 変数 | 用途 |
|------|------|
| `$ARGUMENTS` | スキル呼び出し時の引数全体 |
| `$ARGUMENTS[N]` / `$N` | N番目の引数（0始まり） |
| `${CLAUDE_SKILL_DIR}` | SKILL.md のあるディレクトリのパス |
| `${CLAUDE_SESSION_ID}` | セッションID |

`${CLAUDE_SKILL_DIR}` を使えば、インストール先パスに依存せずスキル内のファイルを参照できる:

```bash
bash ${CLAUDE_SKILL_DIR}/assets/git-sync.sh
```

### 動的コンテキスト注入

`` !`command` `` 構文でスキル読み込み前にシェルコマンドを実行し、結果を埋め込める:

```yaml
- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`
```

## スキル改修時の注意

- SKILL.md は **500行以下**に保つ。大きなコンテンツは `assets/` または `references/` に切り出す
- GitHub API 操作は MCP ツールに統一する（`gh` CLI との混在を避ける）
- `SKILL.md` + `README.md` を同時に更新すること。外部スクリプトがある場合はそれも更新
- スキルの動作が `.claude/rules/` のルールと関連する場合、ルールファイルも整合性を保って更新すること
- シェルスクリプト改修後は `bash -n` で構文チェックすること
- SKILL.md にインラインで埋め込むシェルスクリプトに正規表現パターン（`^[[:space:]]` 等）が含まれる場合、zsh がグロブ展開してエラーになる。`bash /dev/stdin` または一時ファイル経由で実行する旨を明記すること
- 複数フェーズのスキルでは「後半を省略すると危険」ではなく「前半が本体」と記述する。escape hatch（スキップ条件）は最小限にし、フェーズ境界にゲート（前提確認）を設ける
- 他スキルに依存するスキルのテスト・レビュー時も、依存先を実際に Skill ツールで呼び出す。SKILL.md を Read して手動で手順を適用する方法では依存スキルの実行が省略され、正しい検証にならない
- 後続フェーズの手順が SKILL.md 内に見えていると、テキストのゲート指示だけではスキップを防げない。後続フェーズの詳細手順は `references/` に切り出し、前フェーズの出力ファイル存在チェックを物理ゲートにする
- スキルの手順に `rm -f` 等の破壊的コマンドを含めない。一時ファイルは OS の一時領域に任せること
- `-p` 等のオプション引数を持つスキルには「引数の解析」セクションを設ける（smart-commit の形式を参照）。同一プラグイン内で引数パースの書き方を統一すること
- スキル改修時は frontmatter を確認する: 副作用のあるスキルに `disable-model-invocation: true` があるか、`allowed-tools` が設定されているか、`description` に類似スキルとの差別化文言があるか

## 新規スキル追加手順

1. `packages/<plugin>/skills/<skill-name>/` ディレクトリを作成
2. `SKILL.md` を作成（frontmatter: `name` + `description`）
3. `packages/<plugin>/README.md` にスキルの説明・使用例を追加
4. この `CLAUDE.md` のリポジトリ構造セクションにスキルを追記

## 新規プラグイン追加手順

1. `packages/<plugin-name>/` ディレクトリを作成
2. `packages/<plugin-name>/.claude-plugin/plugin.json` を作成
3. `packages/<plugin-name>/skills/` 等にコンポーネントを配置
4. `.claude-plugin/marketplace.json` の `plugins` 配列にエントリを追加
5. `claude --plugin-dir ./packages/<plugin-name>` でローカルテスト
6. この `CLAUDE.md` のリポジトリ構造セクションにプラグインを追記
