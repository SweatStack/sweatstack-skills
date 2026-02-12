#!/bin/sh
# install.sh — SweatStack Skills Installer
set -e

REPO_URL="https://github.com/sweatstack/sweatstack-skills.git"
SKILL_NAME="sweatstack"

usage() {
    echo "Usage: install.sh [--global|-g] [--help|-h]"
    echo ""
    echo "Options:"
    echo "  --global, -g   Install to ~/.claude/skills/$SKILL_NAME (all projects)"
    echo "  --help, -h     Show this help message"
    echo ""
    echo "Default: Install to ./.claude/skills/$SKILL_NAME (current project only)"
    exit 0
}

# Check environment
if [ -z "$HOME" ]; then
    echo "Error: \$HOME is not set. On Windows, use Git Bash or WSL." >&2
    exit 1
fi

# Parse arguments
GLOBAL=0
for arg in "$@"; do
    case "$arg" in
        --global|-g) GLOBAL=1 ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $arg" >&2; usage ;;
    esac
done

# Set target directory
if [ "$GLOBAL" = "1" ]; then
    TARGET_DIR="$HOME/.claude/skills/$SKILL_NAME"
else
    TARGET_DIR=".claude/skills/$SKILL_NAME"
fi

# Check that git is available
if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required but not found." >&2
    exit 1
fi

# Handle existing installation
if [ -d "$TARGET_DIR" ]; then
    if [ -t 0 ]; then
        printf "Directory %s already exists. Replace it? [y/N] " "$TARGET_DIR"
        read -r answer
        case "$answer" in
            [yY]|[yY][eE][sS]) rm -rf "$TARGET_DIR" ;;
            *) echo "Aborted."; exit 0 ;;
        esac
    else
        rm -rf "$TARGET_DIR"
        UPDATING=1
    fi
fi

# Create parent directories
mkdir -p "$(dirname "$TARGET_DIR")"

# Clone to temp directory, extract skill folder
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

git clone --depth 1 --quiet "$REPO_URL" "$TEMP_DIR/repo"
mv "$TEMP_DIR/repo/$SKILL_NAME" "$TARGET_DIR"

if [ "${UPDATING:-0}" = "1" ]; then
    echo "Updated SweatStack skills at: $TARGET_DIR"
else
    echo "Installed SweatStack skills to: $TARGET_DIR"
fi
