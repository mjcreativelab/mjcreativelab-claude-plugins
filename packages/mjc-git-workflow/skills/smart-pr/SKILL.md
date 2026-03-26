---
name: smart-pr
description: 現在のブランチから GitHub Pull Request を作成または更新する。作業内容の自動要約・ラベル付与・関連 Issue 紐づけを行う。ユーザーが「PR 作って」「プルリク作成」「PR 更新して」「/smart-pr」と言ったら起動する。
---

# Smart PR

現在のブランチから PR を作成、または既存 PR を更新する。

## オプション

`-p <プロンプト>`: PR のタイトル・本文・ラベル等に関する追加指示。

例: `-p ドラフトで作って` / `-p レビュアー向け補足に移行手順を書いて`

## ツール選択

GitHub API 操作には **GitHub MCP ツール**を優先（承認不要）。git 操作は Bash。

> **注意**: `issue_write` の `labels` は上書きのため、既存ラベルを取得して結合すること。

## 手順

### 1. 状態確認

以下を並列実行:

**Bash**: `git remote get-url origin`（owner/repo 抽出）、現在のブランチ名、デフォルトブランチの特定（`git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'`）、`git log --oneline <default-branch>..HEAD`、`git diff <default-branch>...HEAD --stat`、`git status --short`

**MCP**: `list_pull_requests`（head: `<owner>:<branch>`）、`get_me`

- PR が存在する → **更新フロー**へ
- PR が存在しない → **新規作成フロー**へ
- デフォルトブランチと差分なし → 中止
- 未コミット変更あり → ユーザーに通知

### 2. デフォルトブランチとの同期確認

以下を順に実行:

1. `git fetch origin` でリモートを最新化
2. `git merge-base --is-ancestor origin/<default-branch> HEAD` でデフォルトブランチの最新が作業ブランチに含まれているか確認
3. 含まれていない（更新がある）場合 → `git merge origin/<default-branch>` を実行
   - **競合が発生した場合** → 競合ファイルを読み取り、コンテキストを理解した上で解決する。解決後の差分をユーザーに提示し、承認を得てから `git add` + `git commit` で完了
   - 競合が複雑で自動解決が困難な場合 → ユーザーに状況を説明し、手動解決を依頼する
4. 含まれている場合 → スキップ

### 3. 未プッシュコミットのプッシュ

リモートブランチ未存在なら `git push -u origin <branch>`、未プッシュあれば `git push`、それ以外はスキップ。

---

## 既存 PR 更新フロー

### 4-U. 差分特定・分析

`pull_request_read` で現在の PR 本文・ラベルを取得。`git log`/`git diff` と照合し、PR に未反映の新規変更を特定。新規コミットがなければ「更新なし」で終了。

### 5-U. PR 本文の更新

既存本文をベースに **追記のみ**（既存記述は変更しない）:
- 「変更内容」に新規コミット分を追記
- 「レビュアー向け補足」に設計判断・影響範囲を追記（必要時）
- 「関連 Issue」に新規 Issue を追記（該当時）
- 「概要」は大きく方向が変わった場合のみ更新提案

ラベルは追加のみ（削除しない）。タイトルは原則変更しない。

### 6-U. ユーザー確認 → 更新実行

更新内容を表示して承認を得る。`update_pull_request` で本文更新、必要なら `issue_write` でラベル追加。最後に PR URL を表示。

---

## 新規 PR 作成フロー

### 4-N. 作業内容の分析

全コミットと diff を読み、変更概要・影響コンポーネント・関連 Issue を把握。

### 5-N. 関連 Issue 探索

コミットメッセージやブランチ名に Issue 番号がなければ `search_issues` で候補を探し、ユーザーに紐づけるか確認。

### 6-N. ラベル選定

変更種別（feature/enhancement/bug/documentation/infra）からラベルを選定。リポジトリ既存ラベルや CLAUDE.md/rules の定義を優先。

### 7-N. PR タイトル・本文作成

**タイトル**: `<type>(<scope>): <日本語説明>` — 70文字以内

**本文テンプレート**:

```markdown
## 概要
<!-- なぜこの変更をしたか 1〜3文 -->

## 変更内容
- ...

## レビュアー向け補足
<!-- 設計判断の理由、影響範囲、既知の制約、テスト方針、注目ポイント -->
<!-- 不要ならセクションごと省略 -->

## 関連 Issue
<!-- あればセクションごと省略 -->
Closes #XX
```

### 8-N. ユーザー確認 → 作成実行

タイトル・本文・ラベル・紐づけ Issue・ベースブランチを表示して承認。`create_pull_request` で作成後、`issue_write` でラベル・アサインを設定。最後に PR URL を表示。

- 関連 Issue は `Closes #XX`（自動クローズ）または `Refs #XX`（参照のみ）
- GitHub Project への追加はしない

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
