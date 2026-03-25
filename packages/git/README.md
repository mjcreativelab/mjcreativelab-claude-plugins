# git

Git ワークフローを自動化する Claude Code プラグインパッケージ。

## Skills

### smart-commit

現在の git 差分を作業内容ごとに適切な単位で分割し、日本語 conventional commits でコミットする。

```
/smart-commit
/smart-commit -p e2e の変更だけコミットして
```

### smart-pr

現在のブランチから GitHub Pull Request を作成・更新する。作業内容の自動要約・ラベル付与・関連 Issue 紐づけを行う。

```
/smart-pr
```

## インストール

```bash
# 1. marketplace として登録
claude plugins marketplace add git@github.com:mjcreativelab/mjcreativelab-claude-plugins.git

# 2. git プラグインをインストール
claude plugins install git
```
