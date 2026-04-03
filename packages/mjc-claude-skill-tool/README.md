# mjc-claude-skill-tool

Claude Code スキルの品質改善ツール。

## なぜ skill-creator だけでは足りないのか

Anthropic 公式の [skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) は、eval 駆動でスキルの出力品質を改善する強力なツールです。しかし、eval は短いセッションで完結するため、**長い会話で初めて顕在化する問題**を構造的に見落とします。

| 問題の種類 | skill-creator | skill-improver Phase 2 |
|---|---|---|
| 出力品質（結果が正しいか） | eval で検出 | - |
| description の発火精度 | 統計的に最適化 | - |
| コンテキスト圧縮時のデータ消失 | 短い eval では再現しない | 再 Read ルールの有無を静的チェック |
| 参照ファイルの一括読み込みによるコンテキスト浪費 | 「動く」ので eval では問題にならない | 読み込みタイミングの設計を検証 |
| 中間データがコンテキストに残り続ける | 同上 | 外部化設計の有無を検証 |
| API レスポンスの丸ごと取り込み | 同上 | 絞り込みルールの有無を検証 |
| TODO / FIXME の残留 | 出力に影響しなければ素通り | Grep で静的検出 |
| 参照ファイルのリンク切れ | 実行時エラーで発覚するが原因特定が遅い | 事前に存在確認 |
| シェルスクリプトの構文エラー | 実行時エラーで発覚 | `bash -n` で事前検出 |

skill-improver はこのギャップを埋めるために、skill-creator の改善ループ完了後に**コンテキスト管理の設計検証**と**静的チェック**を追加実行します。

## スキル一覧

### skill-improver

スキル定義（SKILL.md）を 2 フェーズで改善する。

**Phase 1: skill-creator による eval 駆動の改善**

skill-creator を改善モードで呼び出し、以下のループを実行します:

1. テストケース作成（2〜3 個の現実的なプロンプト）
2. 並列評価（スキルあり / なしのサブエージェントを同時実行）
3. HTML ビューアでレビュー + フィードバック
4. SKILL.md の修正
5. description の統計的最適化（should-trigger / should-not-trigger テスト）

**Phase 2: コンテキスト管理 + 静的チェック**

skill-creator が検出しにくい問題を静的に検証します。

コンテキスト管理チェック:

| チェック項目 | 確認内容 | 該当条件 |
|---|---|---|
| 読み込みタイミング | 参照ファイルの Read が必要なステップまで遅延されているか | 参照ファイルが存在するスキル |
| 圧縮耐性 | コンテキスト圧縮時の再 Read ルールが明記されているか | 複数ステップを持つタスク型スキル |
| 中間データの外部化 | 処理途中のデータをファイルに書き出す設計があるか | ステップが 5 以上のスキル |
| API レスポンスの絞り込み | 必要フィールドだけを抽出するルールがあるか | API 呼び出しを含むスキル |
| バッチ処理設計 | バッチサイズ・中間保存の設計があるか | リスト・配列を反復処理するスキル |
| サブエージェント委譲 | 渡す情報と返却の範囲が明確か | `context: fork` を使うスキル |
| テンプレート肥大化リスク | 将来の肥大化に対する対策があるか | 参照ファイルが 200 行以上のスキル |

静的チェック:

| チェック項目 | 方法 |
|---|---|
| TODO / FIXME / TBD 残留 | Grep で検索 |
| テンプレート未カスタマイズ | プレースホルダーパターンを Grep で検索 |
| 参照ファイルの存在確認 | SKILL.md 内リンクの参照先を Glob で確認 |
| シェルスクリプト構文 | `bash -n` で構文チェック |

## 使い方

```bash
# 基本
/mjc-claude-skill-tool:skill-improver <skill-directory-path>

# 改善の方向性をプロンプトで指定
/mjc-claude-skill-tool:skill-improver <skill-directory-path> -p "<prompt>"
```

### 例

```bash
# パスのみ（skill-creator がインタビューで方向性を決める）
/mjc-claude-skill-tool:skill-improver .claude/skills/my-skill

# プロンプト付き（改善の意図を skill-creator に直接伝える）
/mjc-claude-skill-tool:skill-improver packages/mjc-git-workflow/skills/smart-commit -p "コンテキスト管理を重点的に改善して"
/mjc-claude-skill-tool:skill-improver .claude/skills/deploy -p "eval は不要、一緒に対話的に改善したい"
```

## 前提条件

skill-creator プラグインがインストール済みであること。

```bash
/plugin install skill-creator@claude-plugins-official
```
