# Dotfiles

My personal dotfiles configuration for macOS. This repository contains configuration files for shell, git, editors, and various development tools.

## 🚀 Quick Start

Run the bootstrap script to automatically set up everything:

```bash
git clone https://github.com/levinbaenninger/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap.sh
```

The bootstrap script will:
- Install Homebrew (if not already installed)
- Install all packages from `Brewfile`
- Create symlinks for all configuration files
- Source your new zsh configuration

## 📦 What's Included

### Shell & Terminal
- **zsh** with plugins (autosuggestions, syntax highlighting, fzf-tab)
- **starship** - Fast, customizable prompt
- **tmux** - Terminal multiplexer
- **fzf** - Fuzzy finder
- **zoxide** - Smarter `cd` command
- **atuin** - Shell history search

### File & Directory Tools
- **bat** - Cat clone with syntax highlighting
- **eza** - Modern `ls` replacement
- **fd** - Fast `find` alternative
- **ripgrep** - Fast text search
- **trash-cli** - Safe file deletion

### System Monitoring
- **btop** / **bottom** - System resource monitors
- **dust** - Disk usage analyzer
- **duf** - Disk usage utility
- **procs** - Modern `ps` replacement
- **gping** - Ping with a graph
- **bandwhich** - Network utilization tool

### Git Tools
- **git-delta** - Syntax-highlighting pager for git
- **lazygit** - Terminal UI for git
- **gh** - GitHub CLI

### Development Tools
- **biome** - Fast formatter and linter
- **httpie** - HTTP client
- **hyperfine** - Command-line benchmarking
- **tldr** - Simplified man pages

### Language Runtimes
- **nvm** - Node Version Manager
- **pnpm** - Fast, disk space efficient package manager
- **bun** - Fast JavaScript runtime

### Applications (via Homebrew Casks)
- **Editors**: Cursor, VS Code, JetBrains Toolbox
- **Terminals**: Ghostty, Warp
- **Productivity**: Raycast, Rectangle, Alt-Tab, Stats
- **Development**: OrbStack, Yaak
- **Communication**: Discord, Slack
- **AI**: ChatGPT
- **Project Management**: Linear, Notion
- **Browsers**: Google Chrome, Zen
- **Security**: 1Password
- **Design**: Figma

## 📁 Repository Structure

```
dotfiles/
├── Brewfile              # Homebrew packages and casks
├── scripts/
│   └── bootstrap.sh      # Automated setup script
├── git/
│   └── .gitconfig        # Git configuration
├── zsh/
│   ├── .zshrc            # Main zsh configuration
│   └── starship.toml     # Starship prompt config
├── vscode/
│   └── settings.json     # VS Code settings
└── README.md
```

## 🔧 Manual Setup

If you prefer to set up manually:

1. **Install Homebrew** (if needed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install packages**:
   ```bash
   brew bundle --file=~/dotfiles/Brewfile
   ```

3. **Create symlinks**:
   ```bash
   ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
   ln -sf ~/dotfiles/zsh/aliases.zsh ~/.aliases.zsh
   ln -sf ~/dotfiles/zsh/starship.toml ~/.config/starship.toml
   ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
   ```

## 🎨 Customization

### Adding New Packages

Edit `Brewfile` and add your packages:
```bash
brew "package-name"
cask "application-name"
```

Then run:
```bash
brew bundle --file=~/dotfiles/Brewfile
```

### Updating Packages

Update all Homebrew packages:
```bash
brew update && brew upgrade
```

Or update specific packages from your Brewfile:
```bash
brew bundle --file=~/dotfiles/Brewfile
```

### Modifying Configurations

All configuration files are in their respective directories. After making changes:
- Shell configs: Restart your terminal or run `source ~/.zshrc`
- Git config: Changes take effect immediately
- Starship: Restart your terminal

## 🔄 Keeping Dotfiles Updated

To sync your dotfiles across machines:

```bash
cd ~/dotfiles
git pull origin main
./scripts/bootstrap.sh
```

## 📝 Notes

- The bootstrap script assumes the dotfiles are located at `~/dotfiles`
- If you use a different location, update the `DOTFILES_DIR` variable in `bootstrap.sh`
- Some applications may require manual configuration after installation
- Personal information (like git user name/email) should be customized in `git/.gitconfig`

## 🤝 Contributing

This is a personal dotfiles repository, but feel free to fork and adapt it for your own use!
