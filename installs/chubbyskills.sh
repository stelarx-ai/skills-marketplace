#!/bin/bash
set -e

SKILL_NAME="chubbyskills"
REPO="https://github.com/chubbyguan/chubbyskills.git"
TARGET="$HOME/.stelarx/skills/$SKILL_NAME"

VARIANT="light"
VAULT_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --variant) VARIANT="$2"; shift 2 ;;
    --vault-dir) VAULT_DIR="$2"; shift 2 ;;
    *) shift ;;
  esac
done

echo "[CHUBBY:cloning] Cloning $SKILL_NAME..."
if [ -d "$TARGET" ]; then
  cd "$TARGET" && git pull --ff-only
else
  mkdir -p "$(dirname "$TARGET")"
  git clone --depth 1 "$REPO" "$TARGET"
fi

echo "[CHUBBY:installing] Running setup.sh (variant: $VARIANT)..."
cd "$TARGET"
if [ -f setup.sh ]; then
  bash setup.sh "$VARIANT"
fi

if [ -n "$VAULT_DIR" ]; then
  echo "vault_dir: $VAULT_DIR" >> "$TARGET/chubby.yaml"
fi

echo "[CHUBBY:linking] Creating symlinks..."
mkdir -p "$HOME/.codex/skills" "$HOME/.claude/skills" "$HOME/.agents/skills"
for dest in "$HOME/.codex/skills" "$HOME/.claude/skills" "$HOME/.agents/skills"; do
  link="$dest/$SKILL_NAME"
  [ -L "$link" ] || [ -d "$link" ] && rm -rf "$link"
  ln -s "$TARGET" "$link"
  echo "  → Linked: $link"
done

echo "[CHUBBY:done] $SKILL_NAME installed (variant: $VARIANT)"
