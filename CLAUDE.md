# Claude Plugins Monorepo

Claude Code 用プラグイン（skills, hooks, rules）の開発リポジトリ。

## リポジトリ構造

```
packages/
  mjc-git-workflow/     # Git ワークフロー系スキル
  <plugin-name>/        # 新規プラグインのテンプレート構造
    skills/             # スキル定義（.md ファイル）※必要な場合のみ
    hooks/              # フック定義（シェルスクリプト等）※必要な場合のみ
    rules/              # ルール定義（.md ファイル）※必要な場合のみ
    README.md           # プラグインの説明・使い方
.claude/
  rules/                # プロジェクト共通ルール（Git 規約など）
```

## 配布方法

### 1. marketplace として登録
```
/plugin marketplace add mjcreativelab/claude-plugins
```

### 2. プラグインをインストール
```
/plugin install <plugin-name>@mjcreativelab-claude-plugins
```

## 開発ガイドライン

- 各プラグインは `packages/` 下に独立ディレクトリとして配置
- スキルファイルは YAML frontmatter + Markdown 形式
- フックは `hooks/` ディレクトリにスクリプトとして配置
- ルールは `rules/` ディレクトリに `.md` ファイルとして配置
- 新規プラグインは `packages/` 下にディレクトリを作成し、必要な種類（skills, hooks, rules）のサブディレクトリだけ配置する

## スキルファイル形式

`SKILL.md` の frontmatter は `name`（kebab-case）と `description` の2フィールド:
```yaml
---
name: my-skill
description: スキルの説明（日本語）
---
```

