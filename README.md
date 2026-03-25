# mjcreativelab-claude-plugins

Claude Code 用プラグイン集。skills, hooks, rules を monorepo で管理する。

## パッケージ一覧

| パッケージ | 説明 |
|-----------|------|
| [git](packages/git/) | Git ワークフロー自動化（smart-commit, smart-pr） |

## インストール

```bash
claude plugins install --git git@github.com:mjcreativelab/mjcreativelab-claude-plugins.git --path packages/<package-name>
```

例:

```bash
claude plugins install --git git@github.com:mjcreativelab/mjcreativelab-claude-plugins.git --path packages/git
```

## ライセンス

[MIT](LICENSE)
