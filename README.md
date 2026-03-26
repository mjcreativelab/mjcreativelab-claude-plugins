# mjcreativelab-claude-plugins

Claude Code 用プラグイン集。skills, hooks, rules を monorepo で管理する。

## パッケージ一覧

| パッケージ | 説明 |
|-----------|------|
| [mjc-git-workflow](packages/mjc-git-workflow/) | Git ワークフロー自動化（smart-commit, smart-pr） |

## インストール

```
# 1. marketplace として登録
/plugin marketplace add mjcreativelab/mjcreativelab-claude-plugins

# 2. プラグインをインストール
/plugin install <package-name>@mjcreativelab-claude-plugins
```

例:

```
/plugin install mjc-git-workflow@mjcreativelab-claude-plugins
```

## ライセンス

[MIT](LICENSE)
