#!/usr/bin/env bash
set -euo pipefail

# Smart Git Sync
# デフォルトブランチに切り替え、リモート同期し、マージ済みブランチを一覧表示する。

# --- 1. 未コミット変更チェック ---
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️  未コミットの変更があります:"
  git status --short
  echo ""
  echo "UNCOMMITTED_CHANGES=true"
fi

# --- 2. デフォルトブランチ特定 ---
DEFAULT_BRANCH=""
for candidate in develop main master; do
  if git show-ref --verify --quiet "refs/heads/$candidate"; then
    DEFAULT_BRANCH="$candidate"
    break
  fi
done

if [ -z "$DEFAULT_BRANCH" ]; then
  echo "ERROR: デフォルトブランチ (develop/main/master) が見つかりません"
  exit 1
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# --- 3. チェックアウト & 同期 ---
if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
  git checkout "$DEFAULT_BRANCH"
fi

git fetch --prune
git pull

# --- 4. マージ済みブランチ一覧 ---
PROTECTED_PATTERN='^\*|^[[:space:]]*(main|master|develop)$|^[[:space:]]*release/|^[[:space:]]*hotfix/'
MERGED_BRANCHES=$(git branch --merged | grep -vE "$PROTECTED_PATTERN" || true)

if [ -z "$MERGED_BRANCHES" ]; then
  echo "DELETE_CANDIDATES=none"
else
  echo "DELETE_CANDIDATES<<EOF"
  echo "$MERGED_BRANCHES"
  echo "EOF"
fi

# --- 5. 現在の状態 ---
echo ""
echo "BRANCH=$DEFAULT_BRANCH"
echo "RECENT_COMMITS<<EOF"
git log --oneline -5
echo "EOF"
echo "REMAINING_BRANCHES<<EOF"
git branch
echo "EOF"
