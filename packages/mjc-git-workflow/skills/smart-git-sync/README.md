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
3. 以下の3種類のブランチを検出し、種類ごとに確認後に削除
   - **マージ済みブランチ** — `git branch --merged` で検出、`-d` で安全に削除
   - **リモート削除済みブランチ** — upstream が `gone` のブランチを検出、`-D` で強制削除
   - **squash マージ済みブランチ** — `git commit-tree` + `git cherry` 方式で検出、`-D` で強制削除

## 安全性

- 未コミットの変更がある場合は警告して確認
- `main`, `master`, `develop`, `release/*`, `hotfix/*` は削除対象外
- 3種類のブランチを分けて表示し、それぞれ個別にユーザー確認を取る
- マージ済みブランチは `git branch -d` で安全に削除
- リモート削除済み・squash マージ済みブランチのみ `git branch -D` を使用（検出ロジックで確認済みのもののみ）
