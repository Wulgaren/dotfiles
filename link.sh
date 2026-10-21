#!/bin/bash

# Helper script to add a symlink from ~/.config to dotfiles
# Usage: ./link.sh <config_name>
# Example: ./link.sh nvim
# Example: ./link.sh starship.toml

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

if [ -z "$1" ]; then
    echo "Usage: $0 <config_name>"
    echo "Example: $0 nvim"
    echo "Example: $0 starship.toml"
    exit 1
fi

CONFIG_NAME="$1"
SOURCE_PATH="$CONFIG_DIR/$CONFIG_NAME"
TARGET_PATH="$DOTFILES_DIR/$CONFIG_NAME"

# Check if source exists in ~/.config
if [ ! -e "$SOURCE_PATH" ]; then
    echo "Error: $SOURCE_PATH does not exist"
    exit 1
fi

# If target already exists in dotfiles, ask what to do
if [ -e "$TARGET_PATH" ] || [ -L "$TARGET_PATH" ]; then
    echo "Warning: $TARGET_PATH already exists"
    read -p "Remove and continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    rm -rf "$TARGET_PATH"
fi

# Move the config to dotfiles
echo "Moving $SOURCE_PATH to $TARGET_PATH"
mv "$SOURCE_PATH" "$TARGET_PATH"

# Create symlink
echo "Creating symlink: $SOURCE_PATH -> $TARGET_PATH"
ln -s "$TARGET_PATH" "$SOURCE_PATH"

echo "✓ Done! $CONFIG_NAME is now managed by dotfiles"
