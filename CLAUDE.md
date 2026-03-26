# Claude Plugins Monorepo

Claude Code 用プラグイン（skills, hooks, rules）の開発リポジトリ。

## リポジトリ構造

```
packages/
  <plugin-name>/        # 各プラグインのディレクトリ
    skills/             # スキル定義（.md ファイル）※必要な場合のみ
    hooks/              # フック定義（シェルスクリプト等）※必要な場合のみ
    rules/              # ルール定義（.md ファイル）※必要な場合のみ
    README.md           # プラグインの説明・使い方
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
