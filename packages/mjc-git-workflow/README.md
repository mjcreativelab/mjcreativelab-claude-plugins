# mjc-git-workflow

Git ワークフローを自動化する Claude Code プラグインパッケージ。

## Skills

### smart-commit

変更内容を分析し、作業単位ごとに分割してコミットする。
コミットメッセージは GitMoji + Conventional Commits 形式で、subject を日本語で記述する（例: `✨ feat(auth): ログイン機能を追加`）。
現在のブランチが変更内容に合わない場合は、適切なブランチへの切り替えや新規作成も行う。
`-p` オプションでコミット対象の選別やコミットメッセージに関する追加指示を渡すことができる。

```
/smart-commit
/smart-commit -p e2e の変更だけコミットして
```

### smart-pr

現在のブランチから GitHub Pull Request を作成・更新する。
作業内容の自動要約・ラベル付与・関連 Issue 紐づけを行う。
既存の PR がある場合は、追加コミットの内容を分析して PR の説明・ラベル・関連 Issue を自動更新する。
`-p` オプションで PR の内容に関する追加指示を渡すことができる。

```
/smart-pr
/smart-pr -p レビュアー向け補足にパフォーマンスの懸念を書いて
```

### smart-issue-resolve

GitHub Issue を起点に作業を開始する。
Issue の内容を読み取り、適切なブランチを作成してチェックアウトし、要件に基づいて実装を行う。
作業完了後は `/smart-commit` の使用を提案する（勝手にコミットしない）。
`-p` オプションで作業に関する追加指示を渡すことができる。

```
/smart-issue-resolve #134
/smart-issue-resolve #134 -p テストも書いて
```

## 前提条件

このプラグインの使用には、以下のインストールが必要です。

- **git** — diff, commit, push 等の操作に使用
- **GitHub MCP サーバー** — PR 作成・更新、Issue 連携に使用（[GitHub MCP plugin](https://github.com/anthropics/claude-code-plugins/tree/main/github)）

## インストール

```
# 1. marketplace として登録
/plugin marketplace add mjcreativelab/mjcreativelab-claude-plugins

# 2. mjc-git-workflow プラグインをインストール
/plugin install mjc-git-workflow@mjcreativelab-claude-plugins
```
