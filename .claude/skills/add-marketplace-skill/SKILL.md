---
name: add-marketplace-skill
description: Use when adding a new skill or skill pack to the stelarx skills-marketplace registry — including analyzing a source repo, writing the registry.yaml entry, and creating the install script
---

# Add Marketplace Skill

## Overview

Add a skill to the stelarx skills marketplace. Three files matter: `registry.yaml` (metadata + params), `installs/<id>.sh` (clone + symlink), and the source repo (the skill itself).

## The Pattern

```
registry.yaml          →  one entry per skill/pack
installs/<skill-id>.sh →  one install script per entry
```

## Process

### 1. Analyze the Source Repo

Fetch the repo's file tree and manifest:

```bash
curl -sL 'https://api.github.com/repos/<owner>/<repo>/git/trees/main?recursive=1'
curl -sL 'https://raw.githubusercontent.com/<owner>/<repo>/main/manifest.json'
```

Answer these:
- **Single skill or pack?** If the repo has `skills/<name>/SKILL.md` × N, it's a pack. If it's one top-level `SKILL.md`, it's a single skill.
- **What params?** Does the skill accept config options (variant, API key, target dir)? These become `params` in the registry entry.
- **Install mechanism?** Does it have `setup.sh`, `install.sh`, or just need symlinks?

### 2. Add registry.yaml Entry

Follow the existing schema. Required fields:

```yaml
- id: <kebab-case-id>           # matches installs/<id>.sh filename
  name: "<English Display Name>"
  name_zh: "<中文显示名>"
  description: "<one-line English>"
  description_zh: "<one-line Chinese>"
  icon: "<single emoji>"
  version: "<semver from source>"
  author: "<github-username>"
  homepage: "<repo-url>"
  tags: ["<tag1>", "<tag2>", ...]
  params: []                    # see below
```

**params** — each param maps to a CLI flag in the install script:

```yaml
params:
  - key: <cli-flag-name>        # becomes --<key> in install script
    label: "<English label>"
    label_zh: "<中文标签>"
    type: select | text          # select = dropdown, text = free input
    default: "<default-value>"
    options:                     # only for type: select
      - value: "<option-value>"
        label: "<English>"
        label_zh: "<中文>"
        description: "<what this option does>"
        description_zh: "<中文说明>"
    optional: true               # only for type: text, when not required
    placeholder: "<hint>"        # only for type: text
    placeholder_zh: "<中文提示>"
```

### 3. Create installs/<id>.sh

Conventions every install script follows:

```bash
#!/bin/bash
set -e

SKILL_NAME="<id>"                    # matches registry id
REPO="https://github.com/<owner>/<repo>.git"
TARGET="$HOME/.stelarx/skills/$SKILL_NAME"

# Parse CLI flags (one per registry param)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --<param-key>) VALUE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Clone or pull
echo "[<TAG>:cloning] Cloning $SKILL_NAME..."
if [ -d "$TARGET" ]; then
  cd "$TARGET" && git pull --ff-only
else
  mkdir -p "$(dirname "$TARGET")"
  git clone --depth 1 "$REPO" "$TARGET"
fi

# Run setup if the repo has one
# ...

# Symlink into agent skills dirs
echo "[<TAG>:linking] Creating symlinks..."
mkdir -p "$HOME/.codex/skills" "$HOME/.claude/skills" "$HOME/.agents/skills"
for dest in "$HOME/.codex/skills" "$HOME/.claude/skills" "$HOME/.agents/skills"; do
  link="$dest/$SKILL_NAME"
  [ -L "$link" ] || [ -d "$link" ] && rm -rf "$link"
  ln -s "$TARGET" "$link"
  echo "  → Linked: $link"
done

echo "[<TAG>:done] $SKILL_NAME installed"
```

**Log prefix:** Use `[<SHORT-TAG>:stage]` — uppercase, max 8 chars, unique per skill. Always these stages: `cloning`, `installing`, `linking`, `done`.

**Symlink targets:** Always link into all three: `~/.codex/skills`, `~/.claude/skills`, `~/.agents/skills`.

**For skill packs** (multiple sub-skills in one repo): clone once, then symlink each sub-skill individually. The registry entry's `params` should include a skill selector. Each sub-skill gets its own symlink named after the sub-skill, not the pack.

```bash
# Pack example: one repo, N sub-skills
for skill in "${TO_INSTALL[@]}"; do
  src="$TARGET/skills/$skill"
  for dest in "$HOME/.codex/skills" "$HOME/.claude/skills" "$HOME/.agents/skills"; do
    ln -s "$src" "$dest/$skill"
  done
done
```

## Quick Reference

| What | Where | Pattern |
|------|-------|---------|
| Skill metadata | `registry.yaml` | Add entry under `skills:` |
| Install logic | `installs/<id>.sh` | Clone → setup → symlink |
| Skill id | Both files | kebab-case, matches filename |
| Symlink target | `~/.stelarx/skills/<id>/` | One clone location for all skills |
| Agent dirs | `~/.codex/skills`, `~/.claude/skills`, `~/.agents/skills` | Link into all three |

## Common Mistakes

- **Registry id ≠ install script filename** — must match exactly: `id: foo-bar` ↔ `installs/foo-bar.sh`
- **Missing `chmod +x`** on the install script
- **Log prefix collision** — each skill needs a unique `[TAG]` in echo output
- **Wrong symlink name for packs** — sub-skills keep their original names, not the pack name
