---
name: smart-git-sync
description: デフォルトブランチ（develop or main）にチェックアウトし、fetch/pull してマージ済みブランチを削除する。ユーザーが「同期して」「ブランチ整理」「/smart-git-sync」と言ったら起動する。
---

# Smart Git Sync

以下のスクリプトを Bash で実行し、出力を解釈して処理する。

```bash
bash packages/mjc-git-workflow/scripts/smart-git-sync.sh
```

## 出力の解釈と対応

1. **`UNCOMMITTED_CHANGES=true`** が含まれる場合 → ユーザーに続行するか確認する
2. **`DELETE_CANDIDATES=none`** → 「削除対象のマージ済みブランチはありません」と報告
3. **`DELETE_CANDIDATES`** にブランチ一覧がある場合 → 一覧を表示しユーザーに確認。承認後 `git branch -d <branch>` で各ブランチを削除（`-D` は使わない）
4. 最後に `BRANCH`, `RECENT_COMMITS`, `REMAINING_BRANCHES` を使って結果を報告する
