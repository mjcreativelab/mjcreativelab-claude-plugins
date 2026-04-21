# Empirical Tuning 作業レジューム

中断日時: 2026-04-21

## 全体進捗

| Skill | 状態 | 備考 |
|---|---|---|
| smart-commit | ✅ 収束（iter 2 まで） | [critical] 100%、80 点打ち切り |
| smart-pr | 🟡 iter 1 完了、iter 2 未着手 | 3 シナリオ baseline 計測済み |
| smart-review | ⏸ 未着手 | |
| smart-review-apply | ⏸ 未着手 | |
| smart-issue-plan | ⏸ 未着手 | |
| smart-issue-resolve | ⏸ 未着手 | |
| smart-git-sync | ⏸ 未着手 | |

## iter 0 修正（完了済み、コミット前）

以下のファイルが working tree に未コミットの変更あり:

- `packages/mjc-git-workflow/README.md` — smart-pr セクションに merge 挙動追記
- `packages/mjc-git-workflow/skills/smart-commit/SKILL.md` — description にブランチ切替副作用を追記、Step 2・Step 4 を明確化（iter 2 修正含む）
- `packages/mjc-git-workflow/skills/smart-pr/SKILL.md` — description に merge 副作用を追記
- `packages/mjc-git-workflow/skills/smart-review/SKILL.md` — `disable-model-invocation: true` / `Write` 追加
- `packages/mjc-git-workflow/skills/smart-review-apply/SKILL.md` — `allowed-tools` 追加

設計書（新規ファイル）:
- `packages/mjc-git-workflow/docs/empirical-tuning/` 一式

## smart-commit 結果サマリ

iter 1 → iter 2 改善:
- 解消: ブランチ目的外ファイルの扱い、main からの既存/新規選択肢、`-p` 時のブランチ切替抑制
- 残存: scope 選定の揺れ、`.gitignore` 独立コミット化（軽微）

iter 2 の修正点: Step 2 の既存/新規選択肢の 2 択提示を明文化、Step 4 の除外ファイル扱いと `-p` 時のブランチ切替抑制を明文化。

## smart-pr iter 1 結果サマリ

3 シナリオ全て [critical] 全 ○ で成功。残存不明瞭点:

**共通**:
- リポジトリ名プレースホルダ（dry-run 由来、解消不可）

**シナリオ A（新規作成）**:
- PR body の「レビュアー向け補足」の判断材料不足（軽微）

**シナリオ B（既存更新）**:
- 「レビュアー向け補足」セクション未存在時に新設するか据え置きかが不明
- `wip` ラベルの扱い（SKILL.md の「削除しない」ルールに従って維持、ただしユーザー意図との乖離リスク）

**シナリオ C（merge 必要）**:
- **[最重要]** Step 2 の「コンフリクトなし merge」のユーザー提示要否が曖昧。SKILL.md は「競合発生時のみ提示」と読める記述で、behind 5 のような大きな乖離でも無言で merge するのが意図か不明

### smart-pr iter 2 修正方針候補（未適用）

- Step 2 の記述を「merge 実行前に状況を常にユーザーへ提示する（コンフリクト有無問わず）」に変更
- Step 5-U の更新ルール表に「レビュアー向け補足が未存在時の扱い」を追加
- ラベル `wip` など状態ラベルの扱いを注意事項に追加

メトリクス (iter 1):

| シナリオ | 精度 | steps | duration |
|---|---|---|---|
| A | 100% | 1 | 51s |
| B | ~95% | 1 | 56s |
| C | ~90% (1 部分的) | 1 | 50s |

## レジューム手順

新しいセッションで以下を実行:

```
このファイル (@packages/mjc-git-workflow/docs/empirical-tuning/RESUME.md) を読んで、
smart-pr の iter 2 から再開してください。

対応方針: 「smart-pr iter 2 修正方針候補」のうち最重要項目（Step 2 の merge 提示要否）を
適用し、3 シナリオを並列 dispatch で再評価。

その後、残りの 5 skills（smart-review, smart-review-apply, smart-issue-plan,
smart-issue-resolve, smart-git-sync）を順次チューニング。

各 skill の設計書は同ディレクトリの `<skill>.md` に格納済み。
empirical-prompt-tuning skill の流れ:
1. 設計書のシナリオ + 要件チェックリストを使って subagent dispatch
2. 結果分析 → 1 iter 1 テーマで SKILL.md 修正
3. [critical] 全 ○ かつ不明瞭点減少傾向で 2-3 iter で収束判定
4. 80 点打ち切り OK
```

## 追加メモ

- dry-run ポリシーは設計書 README.md 参照
- subagent dispatch は general-purpose、3 シナリオ並列が基本
- iter ごとに新規 subagent（前回の改善を学習させないため）
- 収束基準: 連続 2 iter で [critical] ○ + 新規不明瞭点なし、または 80 点判断
