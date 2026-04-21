---
name: smart-issue-resolve
description: >
  GitHub Issue ID を受け取り、Issue を読み込んでブランチを作成・チェックアウトし、作業を開始する。
  作業完了後に smart-commit の使用を提案する。
  ユーザーが「Issue やって」「#123 に取り掛かる」「/smart-issue-resolve #123」と言ったら起動する。
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep, Edit, Write, AskUserQuestion
---

# Smart Issue Resolve

GitHub Issue を起点にブランチ作成→実装→完了案内までを行う。

## 引数の解析

`$ARGUMENTS` を以下のルールで解析する:

- `-p` より前の部分 → Issue 番号（`#` は除去）
- `-p` より後の部分 → `{プロンプト}`（実装方針・制約に関する追加指示）
- `-p` がない場合 → `$ARGUMENTS` 全体を Issue 番号として扱い、`{プロンプト}` は空
- Issue 番号が未指定の場合 → AskUserQuestion で Issue 番号を確認する

例: `/smart-issue-resolve #42 -p テストも書いて` → Issue 番号: 42、プロンプト: 「テストも書いて」

## 手順

### 1. Issue の読み取り

引数から抽出した Issue 番号で GitHub MCP ツール（`issue_read`）を呼ぶ。存在しない or クローズ済みなら通知して終了。

コンテキストに残すのは **タイトル・本文冒頭（200 字程度）・ラベル** のみ。他のフィールド（コメント一覧、イベント履歴等）は破棄する。本文が長い場合は要件・受け入れ基準の部分だけ抽出する。

### 2. 作業ツリーの状態確認

現在のブランチ・未コミット変更・ローカルブランチ一覧を取得。

- 未コミット変更あり → ユーザーに通知、続行なら `git stash`
- main 以外にいる → 別作業中の可能性をユーザーに確認

### 3. ブランチ名の決定

CLAUDE.md または `.claude/rules/` の命名規則を優先する。規則がなければ以下のデフォルトを使う:

**フォーマット**: `{type}/issue-{番号}-{説明}`

| ラベル/内容 | type | 例 |
|-------------|------|----|
| bug | `fix` | `fix/issue-134-login-error` |
| feature / enhancement | `feature` | `feature/issue-42-add-oauth` |
| refactoring | `refactor` | `refactor/issue-78-extract-utils` |
| documentation | `docs` | `docs/issue-55-update-api-docs` |
| test | `test` | `test/issue-61-add-unit-tests` |
| その他 | `chore` | `chore/issue-99-update-deps` |

- `{説明}` は英語 kebab-case、3〜5 語以内
- マイルストーン分割がある場合は末尾に `-m{番号}` を付ける（例: `feature/issue-42-add-oauth-m1`）
- 同じ Issue 番号のブランチが既存なら、チェックアウトか新規作成かユーザーに確認

### 4. ブランチ作成・チェックアウト

ユーザー承認後、main を最新にして新規ブランチを作成。stash があれば `git stash pop` で復元する。ただし退避した変更が現 Issue と無関係な別件作業のもの（例: 切り替え前に別 Issue のブランチで未コミット変更があった場合）なら、新規ブランチ上では pop せず stash に残し、ユーザーに「元のブランチに戻ってから復元してください」と案内する。

### 5. 作業の実行

以下の流れで実装する:

1. **コードベース調査** — Issue の要件に関連するファイル・モジュールを特定する
2. **影響範囲の把握** — 変更が波及する箇所を確認する
3. **実装** — Issue の要件・受け入れ基準に沿って変更を加える。`-p` の指示も反映する
4. **動作確認** — テストがあれば実行し、既存テストが壊れていないことを確認する

スコープは Issue 記載内容に限定する。Issue 内容が不明確なら実装前にユーザーに確認する。

### 6. 完了案内

```
作業が完了しました。コミットする場合は `/smart-commit` を実行してください。
```

**勝手にコミットしない** — ユーザーの明示的指示を待つ。

## 注意事項

- `--no-verify` は使わない / force push はしない / push はしない
