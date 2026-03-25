# mjcreativelab-claude-plugins

Claude Code 用プラグイン集。skills, hooks, rules を monorepo で管理する。

## パッケージ一覧

| パッケージ | 説明 |
|-----------|------|
| [git](packages/git/) | Git ワークフロー自動化（smart-commit, smart-pr） |

## インストール

```bash
# 1. marketplace として登録
claude plugins marketplace add git@github.com:mjcreativelab/mjcreativelab-claude-plugins.git

# 2. プラグインをインストール
claude plugins install <package-name>@mjcreativelab-claude-plugins
```

例:

```bash
claude plugins install git@mjcreativelab-claude-plugins
```

## ライセンス

[MIT](LICENSE)
