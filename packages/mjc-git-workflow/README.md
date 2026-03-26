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

## 前提条件

このプラグインの使用には、以下のインストールが必要です。

- **git** — diff, commit, push 等の操作に使用
- **GitHub MCP サーバー** — PR 作成・更新、Issue 連携に使用（[GitHub MCP plugin](https://github.com/anthropics/claude-code-plugins/tree/main/github)）

## インストール

```bash
# 1. marketplace として登録
claude plugins marketplace add git@github.com:mjcreativelab/mjcreativelab-claude-plugins.git

# 2. mjc-git-workflow プラグインをインストール
claude plugins install mjc-git-workflow
```
