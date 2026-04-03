---
name: skill-improver
description: >
  既存スキルの品質改善。skill-creator eval + コンテキスト管理・静的チェックを実行する。
  「改善して」「レビューして」「品質チェック」「eval 回して」「500行超えそう」
  「SKILL.md を見直して」「スキルが効かない」「トリガーされない」「行数オーバー」等で起動。
  新規作成は skill-creator を使う。
argument-hint: "<skill-directory-path> [-p <prompt>]"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Skill, Edit, AskUserQuestion
---

# スキル改善スキル

Phase 1（skill-creator による機能改善）が本スキルの本体である。Phase 2（静的チェック）は Phase 1 の補完であり、Phase 1 なしでは実行できない。

**なぜこの順序なのか**: Phase 1 は機能的な問題（指示の曖昧さ、出力品質、トリガー精度）を実際の実行で検出する。Phase 2 は静的解析のみで、構造やコンテキスト効率の問題を見つける。Phase 2 だけでは機能的な問題を見落とすため、Phase 1 を先に実行する。

**Phase 1 が実行できない場合（skill-creator 未インストール、Skill ツールエラー等）、本スキル全体を中止する。**

## 実行手順

以下の順序で実行する。ファイルの読み込みや分析は Step 1 より前に行わない。

### Step 0: 引数の解析

`$ARGUMENTS` を以下のルールで解析する:

- `-p` より前の部分 → `{スキルパス}`（対象スキルのディレクトリパス）
- `-p` より後の部分 → `{プロンプト}`（skill-creator に渡す追加の改善指示）
- `-p` がない場合 → `$ARGUMENTS` 全体を `{スキルパス}` とし、`{プロンプト}` は空
- `{スキルパス}` が未指定の場合は AskUserQuestion で確認する

### Step 1: skill-creator を呼び出す（Phase 1 — 本体）

対象スキルの読み込みや分析を先に行わず、まず Skill ツールを呼び出す。この呼び出しが skill-creator のインストール確認を兼ねる。

呼び出し先は **skill-creator**（本スキルとは別のスキル）である。skill-improver 自身を Skill ツールで呼び出すのではない。

Skill ツールの呼び出し:
```
skill: "skill-creator:skill-creator"
args: "{スキルパス} を改善したい。eval ループは最大 1 iteration に留めてください。{プロンプト}"
```
（`{プロンプト}` が空の場合は「留めてください。」まで）

**Skill ツールがエラーを返した場合** → AskUserQuestion で以下を案内し、**本スキルの実行を中止する**（Phase 2 含め一切進めない）:
```
skill-creator プラグインが必要です。以下でインストールしてください:
/plugin install skill-creator@claude-plugins-official
インストール後に再度 /skill-improver を実行してください。
```

対象スキルが skill-improver 自身であっても、呼び出す先は skill-creator なので再帰にはならない。skill-creator が eval アプローチ（フル eval / 構造分析ベース）をユーザーに確認するため、このスキル側で事前に聞く必要はない。

**コンテキスト予算**: Phase 2 を確実に実行するため、以下の制約を守る:
- skill-creator の eval ループは **最大 1 iteration** に留める。それ以上の iteration が必要な場合は AskUserQuestion で続行を確認する
- eval 結果の全文引用は避け、パス/フェイル状態と主要な指摘のみを残す

**完了条件**: skill-creator の完了宣言、ユーザーの満足表明、eval 1 iteration 完了のいずれか。

### Step 1 完了時: Phase 1 レポートの書き出し（必須）

Phase 1 の結果を `/tmp/skill-improver-phase1-{スキル名}.md` に書き出す。このファイルは Phase 2 の開始条件として検証される。

```markdown
# Phase 1 結果: {スキル名}
- 実行日時: {現在日時}
- 改善箇所の要約（5 行以内）
- 検出された問題（あれば）
```

### Step 2: Phase 2（物理ゲートあり）

以下の Bash コマンドを実行し、Phase 1 レポートファイルの存在を確認する:

```bash
cat /tmp/skill-improver-phase1-{スキル名}.md
```

- **成功（ファイル内容が表示された）** → [references/phase2-steps.md](references/phase2-steps.md) を Read し、その指示に従う
- **失敗（No such file）** → Phase 1 が未実行である。**本スキルの実行を中止** し、ユーザーに Phase 1 未実行の旨を報告する。phase2-steps.md を Read してはならない

---

## 完了チェック

以下をすべて満たしていることを確認してからスキル改善の完了を報告する:

- [ ] Step 1 が実行された（skill-creator の Skill ツール呼び出しが成功）
- [ ] Phase 1 レポートが `/tmp/skill-improver-phase1-{スキル名}.md` に書き出された
- [ ] Step 2 の物理ゲート（Bash による Phase 1 レポート確認）をパスした
- [ ] phase2-steps.md の手順が完了した
