---
name: skill-improver
description: >
  既存スキルの品質改善。skill-creator eval + コンテキスト管理・静的チェックを実行する。
  「改善して」「レビューして」「品質チェック」「eval 回して」「500行超えそう」等で起動。新規作成は skill-creator を使う。
argument-hint: "<skill-directory-path> [-p <prompt>]"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Skill, Edit, AskUserQuestion
---

# スキル改善スキル

指定されたスキルを **Phase 1 → Phase 2 の順序で** 改善する。**Phase 1 を最初に実行すること。**

- **Phase 1（必須・最初に実行）**: skill-creator による eval 駆動の改善
- **Phase 2（必須・Phase 1 の後に実行）**: コンテキスト管理 + 静的チェック

Phase 1 が品質改善の本体であり、Phase 2 は skill-creator では検出しにくい問題の補完検証である。**Phase 1 をスキップして Phase 2 から開始してはならない。**

## 引数の解析

`$ARGUMENTS` を以下のルールで解析する:

- `-p` より前の部分 → `{スキルパス}`（対象スキルのディレクトリパス）
- `-p` より後の部分 → `{プロンプト}`（skill-creator に渡す追加の改善指示）
- `-p` がない場合 → `$ARGUMENTS` 全体を `{スキルパス}` とし、`{プロンプト}` は空

```
# 例
/skill-improver packages/my-plugin/skills/my-skill -p "コンテキスト管理を重点的に改善して"
  → {スキルパス} = packages/my-plugin/skills/my-skill
  → {プロンプト} = コンテキスト管理を重点的に改善して

/skill-improver .claude/skills/my-skill
  → {スキルパス} = .claude/skills/my-skill
  → {プロンプト} = (空)
```

## 前提

- `{スキルパス}` が未指定の場合は AskUserQuestion で確認する
- skill-creator プラグインがインストール済みであること。未インストールの場合はユーザーに案内する:
  ```
  /plugin install skill-creator@claude-plugins-official
  ```

---

## Phase 1: skill-creator による改善（必須・最初に実行）

> **⚠ このフェーズをスキップしてはならない。** Phase 2 は補完検証であり、品質改善の主要工程は Phase 1 である。

**即座に skill-creator を呼び出す。** Skill ツールのパラメータ: `skill: "skill-creator:skill-creator"`, `args: "{スキルパス} を改善したい。{プロンプト}"`（`{プロンプト}` が空の場合は末尾の句点まで）。

skill-creator が eval アプローチ（フル eval / 構造分析ベース）をユーザーに確認するため、このスキル側で事前に聞く必要はない。

**Phase 1 のコンテキスト予算**: Phase 2 を確実に実行するため、以下の制約を守る:
- skill-creator の eval ループは **最大 1 iteration** に留める。それ以上の iteration が必要な場合は AskUserQuestion で続行を確認する
- eval 結果の全文引用は避け、パス/フェイル状態と主要な指摘のみを残す

**Phase 1 の完了条件**: skill-creator の完了宣言、ユーザーの満足表明、eval 1 iteration 完了のいずれか。skill-creator 呼び出しがエラーになった場合のみ、エラー内容を報告して Phase 2 に進む。

**Phase 1 → Phase 2 の遷移手順**:
1. Phase 1 の知見（改善箇所、検出された問題の要約）と `{スキルパス}` を `/tmp/skill-improver-phase1-{スキル名}.md` に 5 行以内で書き出す
2. 本 SKILL.md の Phase 2 セクションを `Read` で再読み込みする（Phase 1 のコンテキスト消費で Phase 2 の手順が圧縮消失している可能性が高いため）
3. Phase 2 を実行する

---

## Phase 2: コンテキスト管理 + 静的チェック（Phase 1 完了後に実行）

> **前提確認**: Phase 1（skill-creator による改善）が実行済みであること。Phase 1 を実行していない場合は、ここで戻って Phase 1 を実行する。skill-creator 呼び出しエラーで Phase 1 を完了できなかった場合のみ、エラー内容が報告済みであることを確認して続行する。

skill-creator の eval ループでは検出しにくい問題を静的に検証する。短い eval セッションでは再現しない「長い会話でのコンテキスト圧縮」や「読み込み効率」の問題を、SKILL.md の記述から構造的にチェックする。

> **セルフチェック**: Phase 2 には Step 1〜Step 5 がある。以下に Step 5（修正）まで見えていない場合、コンテキスト圧縮で手順が欠落している。この SKILL.md を Read し直してから続行すること。

### Step 1: 改善後のスキルを読み込む

Phase 1 でコンテキスト圧縮が発生している可能性があるため、すべてのファイルを読み直す。

1. `{スキルパス}` のディレクトリを Glob で列挙する（パスが不明な場合は `/tmp/skill-improver-phase1-*.md` を Glob で探すか、AskUserQuestion で確認）
2. SKILL.md を Read する（Phase 1 のキャッシュに頼らない）
3. frontmatter `name` から `{スキル名}` を確定する
4. 補助ファイル（`references/`、`assets/` 等）を一覧として把握する（この時点では Read しない）

### Step 2: コンテキスト管理チェック

`/tmp/skill-improver-phase1-{スキル名}.md` を Read して Phase 1 の知見を把握する（どこを改善したかを踏まえて検証するため）。`{スキル名}` が不明な場合は `/tmp/skill-improver-phase1-*.md` を Glob で探す。ファイルが存在しない場合（skill-creator 呼び出しエラーで Phase 1 が中断した場合等）はそのまま進む。

SKILL.md の構造を [references/context-checklist.md](references/context-checklist.md) の観点で検証する。チェックリストを Read し、「該当条件」に合致する項目のみ検証する。リファレンス型スキル（規約・パターン定義のみ）で該当項目がなければ、その旨を報告して Step 3 に進む。

### Step 3: 静的チェック

SKILL.md およびスキルディレクトリ内のファイルに対して以下を検証する。

| チェック項目 | 方法 |
|---|---|
| TODO / FIXME / TBD 残留 | スキルディレクトリ全体を `Grep` で検索（パターン: `TODO|FIXME|TBD|後で書く|WIP`）。チェックリスト説明文内のマッチ（本 SKILL.md 自身への self-match）は除外する |
| テンプレート未カスタマイズ | `<placeholder>`、`YOUR_`、`REPLACE_ME`、`example.com` 等のプレースホルダーパターンを Grep で検索。同上、チェックリスト説明文内のマッチは除外する |
| 参照ファイルの存在確認 | SKILL.md 内のリンク（`[text](path)` 形式）の参照先がすべて存在するか Glob で確認 |
| シェルスクリプト構文 | `assets/` や `scripts/` 内の `.sh` ファイルがあれば `bash -n` で構文チェック。Bash ツールが利用不可の場合はレポートに「未実施（要手動確認）」と記載する |

### Step 4: レポート出力

発見した問題を以下のフォーマットで報告する。問題がなければ「Phase 2: 問題なし」と報告して終了する。問題が 10 件を超える場合は重要度「高」「中」のみ報告し、「低」はカウントのみ記載する。

レポートは `/tmp/skill-improver-report-{スキル名}.md` にも書き出す（テンプレート: [assets/report-template.md](assets/report-template.md)）。書き出し後は会話にはレポートの要約（問題件数と重要度「高」の項目のみ）を残し、詳細は `/tmp` ファイルを参照する。Step 5 の修正中にコンテキスト圧縮でレポートが失われた場合はこのファイルを再 Read する。

重要度の基準:
- **高**: 実行時エラーまたはコンテキスト溢れに直結する（参照ファイル不在、再 Read 未定義で必須データ消失）
- **中**: 実行はできるがコンテキスト効率が悪い（一括読み込み、レスポンス未絞り込み）
- **低**: 将来の保守性に影響する（肥大化リスク、TODO 残留）

### Step 5: 修正

問題が見つかった場合、AskUserQuestion で次のアクションを確認する:

- **すべて修正** — 重要度「高」から順に Edit で修正する
- **高のみ修正** — 重要度「高」の問題だけ修正する
- **修正しない** — レポートのみで終了する

ユーザーの選択に従い、修正した場合は修正内容を報告する。

---

## 完了チェック

以下をすべて満たしていることを確認してからスキル改善の完了を報告する:

- [ ] Phase 1 が実行された（skill-creator 呼び出しエラー時のみ、エラー内容が報告された）
- [ ] Phase 2 のコンテキスト管理チェックが実行された
- [ ] Phase 2 の静的チェックが実行された
- [ ] Phase 2 のレポートが出力された（「問題なし」を含む）
