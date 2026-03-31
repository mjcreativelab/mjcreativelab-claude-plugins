# Claude Plugins Monorepo

Claude Code 用プラグイン（skills, hooks, rules）の開発リポジトリ。

## よく使うコマンド

```bash
# assets/ 内のシェルスクリプト構文チェック
bash -n packages/<plugin>/skills/<skill-name>/assets/<name>.sh
# 例: bash -n packages/mjc-git-workflow/skills/smart-git-sync/assets/git-sync.sh

# SKILL.md frontmatter 確認（name, description の存在チェック）
head -5 packages/<plugin>/skills/<skill-name>/SKILL.md
# 例: head -5 packages/mjc-git-workflow/skills/smart-commit/SKILL.md
```

## リポジトリ構造

現在のパッケージ一覧（`packages/` 配下）:

```
packages/
  mjc-git-workflow/           # Git ワークフロー系スキル
    skills/smart-commit/       # 差分を作業単位で分割コミット
    skills/smart-pr/           # PR 作成・更新の自動化
    skills/smart-git-sync/     # ブランチ同期・整理
    skills/smart-issue-resolve/ # Issue からブランチ作成〜実装
    skills/smart-issue-plan/   # Issue の実装計画を作成・更新
    skills/smart-review/       # ローカル変更のセルフレビュー
    skills/smart-review-apply/ # レビューフィードバックの適用
.claude/
  rules/                       # プロジェクト共通ルール（Git 規約など）
  skills/
    auto-release/              # バージョン更新・タグ付け・リリース（プロジェクトローカル）
```

新規プラグインのディレクトリ構成（必要なサブディレクトリだけ配置）:

```
packages/<plugin-name>/
  skills/    # スキル定義（SKILL.md）
    <skill-name>/
      assets/      # スキル固有のテンプレート・スクリプト（SKILL.md から参照）
  scripts/   # スキルから呼び出すシェルスクリプト
  hooks/     # フック定義
  rules/     # ルール定義（.md）
  references/  # 複数スキルで共有する参照表・定義（SKILL.md から参照）
  README.md
```

## 配布方法

```bash
# marketplace として登録
/plugin marketplace add mjcreativelab/mjcreativelab-claude-plugins

# プラグインをインストール
/plugin install <plugin-name>@mjcreativelab-claude-plugins
```

## 開発ガイドライン

- 各プラグインは `packages/` 下に独立ディレクトリとして配置
- スキルファイルは YAML frontmatter + Markdown 形式（`name` + `description` の2フィールド必須）
- フックは `hooks/`、ルールは `rules/` に配置

## スキル改修時の注意

- SKILL.md が長くなる場合、テンプレート・スクリプトは `assets/`、共有参照表は `references/` に切り出し、SKILL.md からリンク参照する（コンテキスト削減）
- GitHub API 操作は MCP ツールに統一する（`gh` CLI との混在を避ける）
- `SKILL.md` + `README.md` を同時に更新すること。外部スクリプト（`scripts/*.sh`）がある場合はそれも更新
- スキルの動作が `.claude/rules/` のルールと関連する場合、ルールファイルも整合性を保って更新すること
- シェルスクリプト改修後は `bash -n` で構文チェックすること
- SKILL.md にインラインで埋め込むシェルスクリプトに正規表現パターン（`^[[:space:]]` 等）が含まれる場合、zsh がグロブ展開してエラーになる。`bash /dev/stdin` または一時ファイル経由で実行する旨を明記すること
- スキルから外部スクリプトを参照する場合、インストール先パスは環境ごとに異なる（`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`）ため、固定パスに依存しないこと
- スキルの手順に `rm -f` 等の破壊的コマンドを含めない。一時ファイルは OS の一時領域に任せること

## 新規スキル追加手順

1. `packages/<plugin>/skills/<skill-name>/` ディレクトリを作成
2. `SKILL.md` を作成（frontmatter: `name` + `description`）
3. `packages/<plugin>/README.md` にスキルの説明・使用例を追加
4. この `CLAUDE.md` のリポジトリ構造セクションにスキルを追記

## スキルファイル形式

プロジェクトローカルスキル（`.claude/skills/`）もプラグインスキルと同様に `<name>/SKILL.md` のディレクトリ構造が必須（フラットファイル配置では認識されない）

```yaml
---
name: my-skill
description: スキルの説明（日本語）
---
```
