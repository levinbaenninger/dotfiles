#!/usr/bin/env bash
set -e

echo "Bootstrapping your macOS machine…"

# Install Homebrew if missing
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Brewfile packages
echo "Installing Brewfile packages…"
brew bundle --file="$HOME/dotfiles/Brewfile"

# Symlink dotfiles
echo "Linking dotfiles…"
DOTFILES_DIR="$HOME/dotfiles"

ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/zsh/starship.toml" "$HOME/.config/starship.toml"
ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

echo "Bootstrapping complete! Please restart your terminal."
