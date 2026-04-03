---
name: smart-commit
description: >
  現在の git 差分を作業内容ごとに適切な単位で分割し、日本語 conventional commits でコミットする。
  「コミットして」「差分をコミット」「変更をまとめて」「作業区切りたい」「一旦コミット」
  「今の状態を保存」「ここまでの変更を記録」等で起動する。
  コードレビュー（smart-review）や PR 作成（smart-pr）とは別物。
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep, Edit, Write, AskUserQuestion
---

# Smart Commit

現在の git 差分（staged + unstaged + untracked）を分析し、作業内容ごとにまとまった単位でコミットを作成する。

## 引数の解析

`$ARGUMENTS` を以下のルールで解析する:

- `-p` がある場合 → `-p` より後の部分を `{プロンプト}` として保持する
- `-p` がない場合 → `{プロンプト}` は空
- `{プロンプト}` はコミット対象の選別やメッセージに関する追加指示として、ブランチ連動フィルタリング（Step 4）より優先される

例: `-p e2e の変更だけ` / `-p docs は後回し` / `-p WIP でまとめて`

## 手順

### 1. 早期終了チェック

変更がなければ「コミットする変更がありません」と報告して終了。

### 2. ブランチ確認

現在のブランチ・ブランチ一覧・変更ファイルを取得し、ブランチの適切性を判定する:

- **main/master にいる場合** → 作業ブランチへの切り替えを提案（stash → checkout → stash pop）
- **作業ブランチだが変更がブランチ目的と異なる場合** → 別ブランチへの切り替えを提案
- **適切な場合** → 何も表示せず次へ

切り替え・新規作成前に必ずユーザーに確認を取る。命名規則は CLAUDE.md/rules を参照、なければ `feature/<短い説明>` 形式。

**ブランチ名のルール**（CLAUDE.md/rules の命名規則に加えて以下を遵守）:
- 日本語は使わない（ASCII 英数字 + ハイフン + スラッシュのみ）
- chore/docs/refactor など繰り返し発生しうる作業のブランチは、接尾辞にタイムスタンプを付けて一意にする（例: `docs/update-readme-20260326`、形式は `YYYYMMDD`）

### 3. 差分の収集と分析

`git status`, `git diff`, `git diff --cached`, `git log --oneline -5` を並列実行。差分が大きい場合（目安: 500 行超）はファイル単位の変更要約に切り替え、全行をコンテキストに載せない。

### 4. フィルタリング + コミット単位の分割

**ブランチ連動フィルタリング**（main 以外の場合）:
- ブランチ名から目的を推定。Issue 番号があれば GitHub MCP ツール（`issue_read`）で詳細確認し、タイトル・ラベル・本文冒頭のみ保持する（全フィールドをコンテキストに残さない）
- 目的に合致しない変更は除外（working tree に残す）
- `-p` の指示はブランチ連動より優先

**コミット分割基準**:
- 機能単位でまとめる（レイヤー横断 OK）
- 設定・ドキュメントはコードと別コミット
- 同種の大量変更は1コミットにまとめる

### 5. ignore 確認

untracked に機密ファイル・ビルド成果物・OS生成ファイルがあれば `.gitignore` 追加を提案。

### 6. コミット計画の提示

コミット単位ごとにメッセージとファイル一覧を表示。除外ファイルも明示。ユーザーの承認後に実行。

### 7. コミット実行

ファイル名を明示指定して `git add`（`git add .` は使わない）→ `git commit`。コミットメッセージは HEREDOC で渡す:

```bash
git commit -m "$(cat <<'EOF'
✨ feat(auth): ログイン機能を追加
EOF
)"
```

### 8. 結果報告

`git log --oneline -<作成数>` で一覧表示。

## コミットメッセージ形式

```
<emoji> <type>(<scope>): <subject>
```

- **subject**: 日本語、50文字以下、末尾ピリオドなし
- **scope**: 英語、CLAUDE.md/rules の定義優先。なければディレクトリ/モジュール名から判断
- 必要に応じて body に詳細追記

GitMoji と type の対応: [references/gitmoji-types.md](references/gitmoji-types.md)

## 注意事項

- `Co-Authored-By` トレーラーは付けない
- `--no-verify` は使わない（hook 失敗時は原因を修正して再コミット）
- リモートへの push はしない（ユーザーの明示的指示がある場合のみ）
