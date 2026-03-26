---
name: smart-pr
description: 現在のブランチから GitHub Pull Request を作成または更新する。作業内容の自動要約・ラベル付与・関連 Issue 紐づけを行う。ユーザーが「PR 作って」「プルリク作成」「PR 更新して」「/smart-pr」と言ったら起動する。
---

# Smart PR

現在チェックアウト中のブランチから GitHub Pull Request を作成、または既存の PR を更新する。
コミット履歴とコード差分を分析し、適切な PR 説明・ラベル・Issue 紐づけを自動で行う。

## ツール選択

GitHub API 操作には **GitHub MCP ツール**を優先的に使用する（承認不要で実行できるため）。
git 操作は引き続き Bash で実行する。

| 操作                           | 使用ツール                                                                      |
| ------------------------------ | ------------------------------------------------------------------------------- |
| PR 一覧取得                    | `mcp__plugin_github_github__list_pull_requests`                                 |
| PR 詳細取得                    | `mcp__plugin_github_github__pull_request_read`                                  |
| PR 作成                        | `mcp__plugin_github_github__create_pull_request`                                |
| PR 更新（タイトル・本文）      | `mcp__plugin_github_github__update_pull_request`                                |
| ラベル・アサイン設定           | `mcp__plugin_github_github__issue_write` (method: update, issue_number: PR番号) |
| Issue 検索                     | `mcp__plugin_github_github__search_issues`                                      |
| 認証ユーザー取得               | `mcp__plugin_github_github__get_me`                                             |
| git 操作（log, diff, push 等） | Bash                                                                            |

> **注意**: `issue_write` の `labels` は上書きのため、既存ラベルを維持するには PR の現在のラベルを取得して結合すること。

## 前提: リポジトリ情報の取得

すべてのステップで使用する `<owner>` と `<repo>` は、以下のコマンドで動的に取得する:

```bash
# リモート URL からオーナーとリポジトリ名を抽出
git remote get-url origin | sed -E 's#.+[:/]([^/]+)/([^/.]+)(\.git)?$#\1 \2#'
```

以降の手順で `<owner>`, `<repo>` と記載している箇所は、この結果を使用すること。

## 手順

### 1. 状態の確認

以下を並列実行してブランチの状態を把握する:

**Bash で実行:**

```bash
git remote get-url origin                # オーナー・リポジトリ名を取得
git rev-parse --abbrev-ref HEAD          # 現在のブランチ名
git log --oneline main..HEAD             # main からの差分コミット
git diff main...HEAD --stat              # 変更ファイル統計
git status --short                       # 未コミットの変更
```

**MCP で実行（並列）:**

- `mcp__plugin_github_github__list_pull_requests` (owner: `<owner>`, repo: `<repo>`, head: "`<owner>`:`<ブランチ名>`")
- `mcp__plugin_github_github__get_me` （アサイン用のユーザー名取得）

- **既に PR が存在する場合** → **既存 PR 更新フロー**（ステップ 2 → 3-U へ進む）
- **PR が存在しない場合** → **新規 PR 作成フロー**（ステップ 2 → 3-N へ進む）
- コミットがない（main と同一）場合は中止する
- ステージされていない変更がある場合はユーザーに通知する

### 2. 未プッシュコミットのプッシュ

リモートにプッシュされていないコミットがあるか確認し、あればプッシュする:

```bash
# リモートブランチが存在するか確認
git ls-remote --heads origin "$(git rev-parse --abbrev-ref HEAD)"

# 未プッシュコミットの確認（リモートブランチが存在する場合）
git log --oneline origin/<branch>..HEAD
```

- リモートブランチが存在しない場合: `git push -u origin <branch>` で新規プッシュ
- 未プッシュコミットがある場合: `git push` でプッシュ
- 全てプッシュ済みの場合: スキップ

---

## 既存 PR 更新フロー

### 3-U. 差分の特定

前回の PR 更新以降に追加されたコミットを特定する:

**MCP で実行:**

- `mcp__plugin_github_github__pull_request_read` (method: "get", owner: `<owner>`, repo: `<repo>`, pullNumber: <PR番号>) で本文・タイトル・ラベルを取得

**Bash で実行:**

```bash
git log --oneline main..HEAD
git diff main...HEAD
```

- PR 本文の「変更内容」セクションと `git log` / `git diff` の結果を照合し、PR に反映されていない新規変更を特定する
- 新規コミットがなければ「更新なし」と報告して終了する

### 4-U. 追加内容の分析

新規コミットの内容を分析する:

- 新規コミットの `git show --stat` で変更概要を把握
- 新たに影響するコンポーネントがあるか判断
- 新規コミットメッセージやブランチ名から追加の関連 Issue を探索

### 5-U. PR 本文の更新案作成

既存の PR 本文をベースに以下を更新する:

- **「変更内容」セクション**: 新規コミットに対応する項目を追記
- **「レビュアー向け補足」セクション**: 新規変更に関する設計判断・影響範囲・注意点があれば追記・更新
- **「関連 Issue」セクション**: 新たに紐づける Issue があれば追記
- 既存の記述は変更しない（追記のみ）
- 「概要」セクションは、新規コミットの内容がこれまでの概要と大きく異なる場合のみ更新を提案

### 6-U. ラベルの更新判定

新規コミットで影響するコンポーネントが増えた場合、ラベルの追加を判断する:

- 既存ラベルは削除しない
- リポジトリの既存ラベル一覧と変更内容を照合し、新たに該当するラベルがあれば追加候補とする

### 7-U. ユーザーに確認

更新内容を表示してユーザーの承認を得る:

- 新規コミット一覧
- 本文の変更箇所（diff 形式で表示）
- 追加するラベル（あれば）
- 追加する関連 Issue（あれば）

### 8-U. PR の更新

**MCP で実行:**

1. `mcp__plugin_github_github__update_pull_request` で本文を更新:
   - owner: `<owner>`, repo: `<repo>`, pullNumber: <PR番号>
   - body: <更新後の本文>

2. ラベル追加が必要な場合、`mcp__plugin_github_github__issue_write` でラベルを更新:
   - method: "update", owner: `<owner>`, repo: `<repo>`, issue_number: <PR番号>
   - labels: [<既存ラベル>, <追加ラベル>] （既存ラベルも含めること — 上書きのため）

- タイトルは原則変更しない（ユーザーが明示的に変更を指示した場合のみ）

### 9-U. 結果報告

更新した PR の URL と変更サマリを表示する。

---

## 新規 PR 作成フロー

### 3-N. 作業内容の分析

`git log main..HEAD` の全コミットと `git diff main...HEAD` を読み、以下を判断する:

- **何をしたか**: 変更の概要（機能追加 / バグ修正 / リファクタ / ドキュメント / インフラ等）
- **どのコンポーネントに影響するか**: 変更されたディレクトリから判断
- **関連 Issue**: コミットメッセージやブランチ名に Issue 番号（`#123`）が含まれていないか確認

### 4-N. 関連 Issue の探索

ブランチ名・コミットメッセージから Issue 番号が特定できない場合、MCP で候補を探す:

**MCP で実行:**

- `mcp__plugin_github_github__search_issues` (query: "<ブランチ名から抽出したキーワード> is:open", owner: `<owner>`, repo: `<repo>`, perPage: 10)

候補が見つかった場合はユーザーに紐づけるか確認する。見つからない場合はスキップ。

### 5-N. ラベルの選定

変更内容から適切なラベルを選定する。

**変更種別ラベル**（1つ選択）:
| ラベル | 条件 |
|--------|------|
| `feature` | 新機能の追加 |
| `enhancement` | 既存機能の改善 |
| `bug` | バグ修正 |
| `documentation` | ドキュメントのみの変更 |
| `infra` | CI/CD、デプロイ、インフラ設定等 |

> **注意**: 上記は一般的なラベル例。リポジトリに既存のラベルがある場合はそちらを優先して使用する。CLAUDE.md や rules にラベル規則が定義されていればそれに従う。

### 6-N. PR タイトルの作成

形式: `<type>(<scope>): <日本語で簡潔な説明>`

- smart-commit と同じ conventional commits 形式
- 70 文字以内に収める
- scope はコミットの scope から代表的なものを選ぶか、複数コンポーネントなら省略

### 7-N. PR 本文の作成

以下のテンプレートで本文を作成する:

```markdown
## 概要

<!-- 1〜3 文で「なぜこの変更をしたか」を説明 -->

## 変更内容

<!-- 箇条書きで主要な変更を列挙 -->

- ...

## レビュアー向け補足

<!-- AI レビューエージェントや人間のレビュアーが、変更内容だけでは判断しにくい背景・意図・注意点を記載する。例: -->
<!-- - 設計判断の理由（なぜこのアプローチを選んだか、他の選択肢を棄却した理由） -->
<!-- - 影響範囲・副作用（この変更が他のコンポーネントに与える影響） -->
<!-- - 既知の制約・TODO（今回は対応しないが将来対応が必要な点） -->
<!-- - テスト方針（どのようにテスト・動作確認したか、特殊な確認手順） -->
<!-- - レビュー時に特に見てほしいポイント -->
<!-- 補足が不要な場合はセクションごと省略 -->

## 関連 Issue

<!-- あれば。なければセクションごと省略 -->

Closes #XX
```

### 8-N. ユーザーに確認

PR を作成する前に以下を表示してユーザーの承認を得る:

- タイトル
- 本文（プレビュー）
- ラベル
- 紐づける Issue
- ベースブランチ

### 9-N. PR の作成

**MCP で実行（順次）:**

1. `mcp__plugin_github_github__create_pull_request` で PR を作成:
   - owner: `<owner>`, repo: `<repo>`
   - title: <タイトル>
   - head: <ブランチ名>
   - base: "main"
   - body: <本文>

2. `mcp__plugin_github_github__issue_write` でラベルとアサインを設定:
   - method: "update", owner: `<owner>`, repo: `<repo>`
   - issue_number: <作成された PR 番号>
   - labels: [<ラベル1>, <ラベル2>]
   - assignees: [<ステップ 1 で取得したユーザー名>]

- 関連 Issue がある場合は本文の `Closes #XX` で自動紐づけ（マージ時に自動クローズ）
- 単に参照するだけの場合は `Refs #XX` を使う
- GitHub Project への追加はしない（Issue 側で管理）

### 10-N. 結果報告

作成した PR の URL を表示する。

---

## 注意事項

- **MCP ツールの `body` パラメータには `\n` エスケープシーケンスを使わず、実際の改行文字を含めること。** `\n` を使うと GitHub 上でリテラル文字列として表示されてしまう
- `--no-verify` は使わない
- ドラフト PR にしたい場合はユーザーが明示的に指示した場合のみ `--draft` を付ける
- force push はしない
- 既存 PR 更新時、既存の記述は削除・変更しない（追記のみ）
- 既存 PR のタイトルは原則変更しない
