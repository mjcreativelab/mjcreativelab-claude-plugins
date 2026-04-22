# mjc-code-develop-tools

コード開発ライフサイクル（設計 → レビュー → セキュリティ監査）を横断で支援するスキル群。

会話コンテキスト（要件・議論内容・設計意図）を踏まえた判断が必要なフェーズを対象にしており、`/software-architect` → 実装 → `/code-reviewer` → `/security-auditor` の流れで組み合わせて使うことを想定する。

## スキル一覧

### software-architect

要件やスペックから「あるべきソフトウェア設計」を言語化する。新機能の設計着手時、既存機能の再設計時、仕様の解像度を上げたいときに使う。画面デザイン（UI/UX）は対象外。

主な出力:

- 設計サマリ（目的 / スコープ / 非スコープ）
- データモデル・API・主要コンポーネントの責務
- 主要トレードオフと選択理由
- 実装タスク振り分け（Codex 向きの閉じたタスク / Cursor 向きの横断タスク）
- 想定リスクと未解決事項

### code-reviewer

実装されたコードを仕様整合・設計適合・可読性の観点でレビューする。PR / 変更差分のレビュー、コミット前のセルフレビューに使う。重要変更は Codex クロスチェックを推奨する。

観点:

- 仕様整合 / 設計適合 / 可読性 / テスト / オーバーエンジニアリング
- 横断影響（skills・設定・関連ドメインへの影響漏れ）

出力は「🚫 ブロッカー / ⚠️ 推奨 / 💬 nit / ✅ Good / 🔄 横断影響」の 5 区分で整理する。

### code-reviewer-adversarial

Breaker（Claude Opus 4.7）× Judge（Codex gpt-5.4、`codex:rescue` 経由）の二者構造で、反例生成とテスト実行により「本当の欠陥」のみを抽出する敵対的レビュー。重要変更・最終ゲート・見逃したくない場面に使う。

特徴:

- **Breaker** は3 persona（Security / Performance / Specification）で反例を列挙し、failing テストとして生成・実行する
- **Judge**（別系統モデル）が「真の欠陥 / 仕様未定 / 低優先度 / ノイズ」に裁定し、共犯化を避ける
- 出力は「指摘内容 / 再現条件 / 最小反例 / 影響範囲 / 重大度 / 修正案 / 確信度」の7フィールド固定スキーマ
- レビュー対象は引数で指定可能（PR 番号 / ブランチ / `ref..ref` / パス）

引数:

```
/code-reviewer-adversarial [<PR番号|branch|ref..ref|path>] [--test <cmd>] [-p <重点観点>]
```

通常のレビューは `/code-reviewer` を使い、このスキルは認証・決済・スキーマ・外部 API などの重要変更に限定して使う。

### security-auditor

脅威モデル・認可・データフロー・設計リスクの観点からセキュリティ監査を行う。新機能の設計時、外部接点を変更するとき、認証・認可・データ扱いに触れるときに使う。

観点:

- 脅威モデル（STRIDE / 信頼境界）
- 認可（権限設計・多層防御・最小権限）
- データフロー（PII・秘密情報の経路と保管・ログ出力）
- 設計リスク（TOCTOU・Confused Deputy など）

実装レベルの脆弱性スキャンは Codex に委譲する前提で、設計レベルのリスク可視化に集中する。

## 使い方

```bash
# 設計
/mjc-code-develop-tools:software-architect

# コードレビュー
/mjc-code-develop-tools:code-reviewer

# 敵対的コードレビュー（Breaker × Judge）
/mjc-code-develop-tools:code-reviewer-adversarial [<PR番号|branch|ref..ref|path>] [--test <cmd>] [-p <重点観点>]

# セキュリティ監査
/mjc-code-develop-tools:security-auditor
```

各スキルは会話コンテキストを前提に動作する。コンテキスト隔離での独立監査が必要な場合はプロジェクトの `code-reviewer` / `security-auditor` subagent を別途利用する。

## 前提条件

追加の依存はない。`Read` / `Grep` / `Glob` など標準ツールで動作する。
