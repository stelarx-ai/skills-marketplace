#!/bin/bash
set -e

SKILL_NAME="account-launch-pack"
REPO="https://github.com/chenjin-cmd/agent-skills-launch-pack_.git"
TARGET="$HOME/.stelarx/skills/$SKILL_NAME"

# All 5 sub-skills in the pack
ALL_SKILLS=(
  "wechat-account-launch-expert"
  "xiaohongshu-account-launch-expert"
  "douyin-account-launch-expert"
  "channels-account-launch-expert"
  "x-twitter-cold-start-expert"
)

SELECTED="all"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills) SELECTED="$2"; shift 2 ;;
    *) shift ;;
  esac
done

echo "[LAUNCH:cloning] Cloning $SKILL_NAME..."
if [ -d "$TARGET" ]; then
  cd "$TARGET" && git pull --ff-only
else
  mkdir -p "$(dirname "$TARGET")"
  git clone --depth 1 "$REPO" "$TARGET"
fi

# Resolve which skills to install
if [ "$SELECTED" = "all" ]; then
  TO_INSTALL=("${ALL_SKILLS[@]}")
else
  TO_INSTALL=("${SELECTED}-account-launch-expert")
  # x-twitter uses a different naming convention
  [ "$SELECTED" = "x-twitter" ] && TO_INSTALL=("x-twitter-cold-start-expert")
  # channels also
  [ "$SELECTED" = "channels" ] && TO_INSTALL=("channels-account-launch-expert")
fi

echo "[LAUNCH:linking] Creating symlinks for selected skills..."
mkdir -p "$HOME/.codex/skills" "$HOME/.claude/skills" "$HOME/.agents/skills"

for skill in "${TO_INSTALL[@]}"; do
  src="$TARGET/skills/$skill"
  if [ ! -d "$src" ]; then
    echo "  ⚠ Skipping $skill: not found in repo"
    continue
  fi

  for dest in "$HOME/.codex/skills" "$HOME/.claude/skills" "$HOME/.agents/skills"; do
    link="$dest/$skill"
    [ -L "$link" ] || [ -d "$link" ] && rm -rf "$link"
    ln -s "$src" "$link"
    echo "  → Linked: $link"
  done
done

echo "[LAUNCH:done] $SKILL_NAME installed (skills: ${TO_INSTALL[*]})"
