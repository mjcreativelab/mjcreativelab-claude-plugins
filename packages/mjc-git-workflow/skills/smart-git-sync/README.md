# smart-git-sync

デフォルトブランチ（develop or main）にチェックアウトし、fetch/pull してマージ済みブランチを削除するスキル。

## 使い方

```
/smart-git-sync
```

または「同期して」「ブランチ整理」と伝える。

## 動作内容

1. デフォルトブランチ（develop > main > master の優先順）にチェックアウト
2. `git fetch --prune` と `git pull` でリモートと同期
3. マージ済みのローカルブランチを一覧表示し、確認後に削除

## 安全性

- 未コミットの変更がある場合は警告して確認
- `main`, `master`, `develop`, `release/*`, `hotfix/*` は削除対象外
- `git branch -d`（小文字）のみ使用し、未マージブランチの誤削除を防止
- リモートブランチの削除はしない
