# mjcreativelab-claude-plugins

Claude Code 用プラグイン集。skills, hooks, rules を monorepo で管理する。

## パッケージ一覧

| パッケージ | 説明 |
|-----------|------|
| [mjc-git-workflow-tools](packages/mjc-git-workflow-tools/) | Git ワークフロー自動化（smart-issue-resolve, smart-commit, smart-pr, smart-review 等） |
| [mjc-claude-improver-tools](packages/mjc-claude-improver-tools/) | スキル品質改善ツール（skill-creator 連携 + コンテキスト管理・静的チェック） |

## インストール

```
# 1. marketplace として登録
/plugin marketplace add mjcreativelab/mjcreativelab-claude-plugins

# 2. プラグインをインストール
/plugin install <package-name>@mjcreativelab-claude-plugins
```

例:

```
/plugin install mjc-git-workflow-tools@mjcreativelab-claude-plugins
/plugin install mjc-claude-improver-tools@mjcreativelab-claude-plugins
```

## ライセンス

[MIT](LICENSE)
