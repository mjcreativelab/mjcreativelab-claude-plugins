---
name: smart-pr
description: >
  現在のブランチから GitHub Pull Request を作成または更新する。作業内容の自動要約・ラベル付与・関連 Issue 紐づけを行う。
  必要に応じてデフォルトブランチを現在のブランチへマージしてから push する（副作用あり）。
  「PR 作って」「プルリク作成」「PR 更新して」「/smart-pr」と言ったら起動する。
  コミット（smart-commit）やレビュー（smart-review）とは別物。
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep, AskUserQuestion
---

# Smart PR

現在のブランチから PR を作成、または既存 PR を更新する。

## 引数の解析

`$ARGUMENTS` を以下のルールで解析する:

- `-p` がある場合 → `-p` より後の部分を `{プロンプト}` として保持する
- `-p` がない場合 → `{プロンプト}` は空
- `{プロンプト}` は PR のタイトル・本文・ラベル等に関する追加指示として使う

例: `-p ドラフトで作って` / `-p レビュアー向け補足に移行手順を書いて`

## ツール選択

GitHub API 操作には **GitHub MCP ツール**を優先（承認不要）。git 操作は Bash。

> **注意**: `issue_write` の `labels` は上書きのため、既存ラベルを取得して結合すること。

## 手順

### 1. 状態確認

以下を並列実行:

**Bash**（1 回の呼び出しで連結実行）:
```bash
git remote get-url origin && git branch --show-current && git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' && git status --short
```

> デフォルトブランチ検出に `symbolic-ref` が失敗した場合は `develop` → `main` → `master` の順で `git show-ref --verify refs/remotes/origin/<name>` を試す。

**MCP**（並列）:
- `list_pull_requests`（head: `<owner>:<branch>`）で既存 PR を検索
- `get_me` でアサイン用ユーザー名を取得

**判定**:
- デフォルトブランチにいる → 「作業ブランチで実行してください」と案内して終了
- デフォルトブランチと差分なし → 「PR にする変更がありません」で終了
- 未コミット変更あり → ユーザーに通知（`/smart-commit` を提案）
- PR が存在する → **更新フロー**（Step 4-U）へ
- PR が存在しない → **新規作成フロー**（Step 4-N）へ

### 2. デフォルトブランチとの同期確認

```bash
git fetch origin
git merge-base --is-ancestor origin/<default-branch> HEAD
```

- 含まれている → スキップ
- 含まれていない（デフォルトブランチに新しいコミットがある）→ **merge 実行前に behind の件数（例: 「behind 5 コミット」）をユーザーに提示して承認を得てから** `git merge origin/<default-branch>` を実行する（コンフリクトの有無に関わらず提示は必須）
  - **競合が発生した場合** → 競合ファイルの一覧と内容をユーザーに提示し、解決方針を確認してから対応する。ユーザーの承認なく `git add` しない
  - 競合なしでマージ成功 → 次へ

### 3. 未プッシュコミットのプッシュ

- リモートブランチ未存在 → `git push -u origin <branch>`
- 未プッシュコミットあり → `git push`
- それ以外 → スキップ

Bash で diff の統計も取得:
```bash
git log --oneline <default-branch>..HEAD
git diff <default-branch>...HEAD --stat
```

---

## 既存 PR 更新フロー

### 4-U. 差分特定・分析

`pull_request_read` で現在の PR を取得し、**タイトル・本文・ラベル・番号のみ保持** する（他のフィールドはコンテキストから破棄）。`git log`/`git diff` と照合し、PR に未反映の新規変更を特定する。

新規コミットがなければ「更新する変更がありません」で終了。

### 5-U. PR 本文の更新

既存本文をベースに、新規変更分を **追記** する（既存記述は変更しない）:

| セクション | 更新ルール |
|-----------|-----------|
| 概要 | 方向性が大きく変わった場合のみ更新を提案 |
| 変更内容 | 新規コミット分の箇条書きを末尾に追記 |
| レビュアー向け補足 | 設計判断・影響範囲の追加があれば追記 |
| 関連 Issue | 新規 Issue があれば追記 |

- ラベルは追加のみ（削除しない）
- タイトルは原則変更しない

### 6-U. ユーザー確認 → 更新実行

更新内容（本文の差分・追加ラベル）を表示して承認を得る。`update_pull_request` で本文更新、必要なら `issue_write` でラベル追加。最後に PR URL を表示。

---

## 新規 PR 作成フロー

### 4-N. 作業内容の分析

全コミットと diff を読み、変更概要・影響コンポーネント・関連 Issue を把握。

### 5-N. 関連 Issue 探索

コミットメッセージやブランチ名に Issue 番号があればそれを使う。なければ `search_issues` で候補を探し、ユーザーに紐づけるか確認。

### 6-N. ラベル選定

リポジトリ既存ラベル（`list_issues` の `labels` で確認可）の中から、変更種別に合致するものを選定する。プロジェクト側に独自のラベル運用ルール（CLAUDE.md・AGENTS.md・README 等で明示されている場合）があればそちらを優先する。

汎用的な対応指針:

| 変更種別           | 推奨ラベル候補（リポジトリに存在するものを使う） |
| ------------------ | ------------------------------------------------ |
| 新機能・機能追加   | `feature`, `enhancement`                         |
| バグ修正           | `bug`, `fix`                                     |
| ドキュメント       | `documentation`, `docs`                          |
| ビルド・CI・依存   | `infra`, `chore`, `ci`                           |
| リファクタリング   | `refactor`                                       |
| テスト             | `test`                                           |

リポジトリに該当ラベルが存在しない場合はラベル無しでも可。新規ラベル作成は提案しない。

### 7-N. PR タイトル・本文作成

**タイトル**: `<type>(<scope>): <日本語説明>` — 70文字以内

**本文**: [assets/pr-template.md](assets/pr-template.md) を使用。

### 8-N. ユーザー確認 → 作成実行

タイトル・本文・ラベル・紐づけ Issue・ベースブランチを表示して承認を得る。

`create_pull_request` で作成後、`issue_write` でラベル・アサインを設定。最後に PR URL を表示。

- 関連 Issue は `Closes #XX`（自動クローズ）または `Refs #XX`（参照のみ）
- GitHub Project への追加はしない

## コンテキスト管理

長い会話でコンテキスト圧縮が発生した場合、Step 1 で取得した以下の情報を再取得する:
- `git remote get-url origin`（owner/repo）
- `git branch --show-current`（ブランチ名）
- デフォルトブランチ名

ただし本スキルは新規セッションでの実行を推奨しており（README 参照）、通常は圧縮が発生しない。

## 注意事項

- **MCP ツールの `body` パラメータには、エスケープシーケンス (`\n`) ではなく実際の改行文字を含めること。** `\n` リテラルを渡すと GitHub 上で改行されず1行表示になる。正しい例:
  ```
  body: "## 概要
  ここに説明

  ## 変更内容
  - 項目1"
  ```
  誤った例: `body: "## 概要\nここに説明\n\n## 変更内容\n- 項目1"`
- `--no-verify` は使わない
- force push はしない
- ドラフト PR はユーザーの明示的指示がある場合のみ
