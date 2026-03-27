---
name: smart-issue-resolve
description: GitHub Issue ID を受け取り、Issue を読み込んでブランチを作成・チェックアウトし、作業を開始する。作業完了後に smart-commit の使用を提案する。ユーザーが「Issue やって」「#123 に取り掛かる」「/smart-issue-resolve #123」と言ったら起動する。
---

# Smart Issue Resolve

GitHub Issue を起点にブランチ作成→実装→完了案内までを行う。

## オプション

`-p <プロンプト>`: 実装方針・制約に関する追加指示。

例: `-p テストも書いて` / `-p 最小限の変更で`

## 手順

### 1. Issue の読み取り

引数から Issue 番号を抽出（`#` 除去）し、`issue_read` でタイトル・本文・ラベルを取得。存在しない or クローズ済みなら通知して終了。

### 2. 作業ツリーの状態確認

現在のブランチ・未コミット変更・ローカルブランチ一覧を取得。

- 未コミット変更あり → ユーザーに通知、続行なら `git stash`
- main 以外にいる → 別作業中の可能性をユーザーに確認

### 3. ブランチの作成

**命名規則**（CLAUDE.md/rules の定義を優先、なければ以下）:

| ラベル/内容 | 形式 | 例 |
|-------------|------|----|
| bug | `fix/<issue番号>-<説明>` | `fix/134-login-error` |
| feature/enhancement | `feat/<issue番号>-<説明>` | `feat/42-add-oauth` |
| documentation | `docs/<issue番号>-<説明>` | `docs/55-update-api-docs` |
| その他 | `chore/<issue番号>-<説明>` | `chore/99-update-deps` |

`<説明>` は英語 kebab-case、3〜5単語以内。

同じ Issue 番号のブランチが既存なら、チェックアウトか新規作成かユーザーに確認。

### 4. ブランチ作成・チェックアウト

ユーザー承認後、main を最新にして新規ブランチを作成。stash があれば `git stash pop` で復元。

### 5. 作業の実行

Issue の要件・受け入れ基準・制約を把握し、`-p` の指示も加えて実装。スコープは Issue 記載内容に限定。

### 6. 完了案内

```
作業が完了しました。コミットする場合は `/smart-commit` を実行してください。
```

**勝手にコミットしない** — ユーザーの明示的指示を待つ。

## 注意事項

- Issue 内容が不明確なら実装前にユーザーに確認
- `--no-verify` は使わない / force push はしない / push はしない
