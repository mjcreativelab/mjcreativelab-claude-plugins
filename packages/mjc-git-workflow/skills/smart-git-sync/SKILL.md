---
name: smart-git-sync
description: デフォルトブランチ（develop or main）にチェックアウトし、fetch/pull してマージ済みブランチを削除する。ユーザーが「同期して」「ブランチ整理」「/smart-git-sync」と言ったら起動する。
---

# Smart Git Sync

[assets/git-sync.sh](assets/git-sync.sh) を読み込んで実行する。

zsh ではインライン実行しないこと（正規表現がグロブ展開されるため）。
一時ファイルに書き出して `bash` で実行するか、`bash /dev/stdin` 経由で渡す。
一時ファイルの明示削除は不要（OS の一時領域に任せる）。

## 出力の解釈と対応

1. **`UNCOMMITTED_CHANGES=true`** が含まれる場合 → ユーザーに続行するか確認する
2. **`DELETE_CANDIDATES=none`** → 「削除対象のマージ済みブランチはありません」と報告
3. **`DELETE_CANDIDATES`** にブランチ一覧がある場合 → 一覧を表示しユーザーに確認。承認後 `git branch -d <branch>` で各ブランチを削除
4. **`GONE_CANDIDATES`** にブランチ一覧がある場合 → 「リモートで削除済み」として一覧を表示しユーザーに確認。承認後 `git branch -D <branch>` で削除
5. **`SQUASH_CANDIDATES`** にブランチ一覧がある場合 → 「squash マージ済み（未マージ扱い）」として一覧を表示しユーザーに確認。承認後 `git branch -D <branch>` で削除
6. 最後に `BRANCH`, `RECENT_COMMITS`, `REMAINING_BRANCHES` を使って結果を報告する

## 削除時の注意

- マージ済みブランチ (`DELETE_CANDIDATES`) → `git branch -d`（安全な削除）
- リモート削除済み・squash マージ済みブランチ (`GONE_CANDIDATES`, `SQUASH_CANDIDATES`) → `git branch -D`（強制削除）
- 3種類を分けて表示し、それぞれ個別にユーザー確認を取ること
- 一括削除ではなく種類ごとに確認・削除を行う
