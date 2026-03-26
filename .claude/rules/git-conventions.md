# Git Conventions

- Commit messages: 日本語 OK, conventional commits preferred
- Branch strategy: feature branch → main
- **main への直接コミットは禁止** — 必ず feature branch を作成し、PR 経由でマージすること
- **すべての変更は PR を作成する** — レビューなしで main に直接 push しない

## ブランチ命名規則

### フォーマット

```
{type}/issue-{番号}-{簡潔な説明}
```

### type prefix

| prefix      | 用途                             |
| ----------- | -------------------------------- |
| `feature/`  | 新機能・機能追加                 |
| `fix/`      | バグ修正                         |
| `refactor/` | リファクタリング（機能変更なし） |
| `docs/`     | ドキュメントのみの変更           |
| `chore/`    | ビルド・CI・依存関係など雑務     |
| `test/`     | テストの追加・修正               |

### ルール

- **kebab-case**（小文字 + ハイフン区切り）を使う
- Issue に紐づく作業は必ず `issue-{番号}` を含める
- 説明部分は **英語・3〜5 語** 程度に収める
- マイルストーン分割がある場合は末尾に `-m{番号}` を付ける

## PR / Issue 作成ルール

- PR・Issue 作成時は作成者を自動アサインする（`gh api user` で取得した GitHub ユーザー名を使用）
- Issue 作成時は内容に適した既存ラベルを付与する

### Issue 作成の手順

- **Issue 作成** — GitHub MCP ツール (`issue_write`) を使用。ラベル付与・アサインもここで行う
