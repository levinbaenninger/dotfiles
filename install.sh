#!/usr/bin/env bash
# Bootstrap a new machine (macOS, WSL, Linux VM, exe.dev):
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/levinbaenninger/dotfiles/main/install.sh)"
#
# Or from a clone:  ~/dotfiles/install.sh
#
# Non-interactive knobs (all optional):
#   DOTFILES_PROFILE=mac|wsl|exe|linux   override auto-detection
#   DOTFILES_WORK=1|0                    pull work config from 1Password
#                                        (headless Linux: needs the service account
#                                        token in ~/.config/dotfiles/op-service-account-token)
#   DOTFILES_REPO / DOTFILES_BRANCH      clone a fork or branch
set -euo pipefail

# Everything runs inside main(), called on the last line. With `curl | bash`,
# bash reads the script from the pipe as it executes; a command that reads
# stdin (brew bundle does) would otherwise swallow the rest of the script.
main() {
  REPO="${DOTFILES_REPO:-https://github.com/levinbaenninger/dotfiles.git}"
  BRANCH="${DOTFILES_BRANCH:-main}"
  DOTFILES_DIR="$HOME/dotfiles"

  log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

  os="$(uname -s)"

  # 1. OS prerequisites for Homebrew (Linux only).
  if [[ "$os" == "Linux" ]] && command -v apt-get >/dev/null; then
    log "Installing apt prerequisites"
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
      build-essential procps curl file git ca-certificates
  fi

  # 2. Homebrew.
  if [[ "$os" == "Darwin" ]]; then
    brew_prefix=$([[ "$(uname -m)" == "arm64" ]] && echo /opt/homebrew || echo /usr/local)
  else
    brew_prefix=/home/linuxbrew/.linuxbrew
  fi
  if [[ ! -x "$brew_prefix/bin/brew" ]]; then
    log "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$("$brew_prefix/bin/brew" shellenv bash)"
  export HOMEBREW_NO_ENV_HINTS=1

  # Headless work machines (Linux, not WSL): 1Password CLI + service account,
  # because chezmoi reads the Work vault while rendering templates.
  token_file="$HOME/.config/dotfiles/op-service-account-token"
  if [[ "$os" == "Linux" && "${DOTFILES_WORK:-0}" == "1" ]] && ! grep -qi microsoft /proc/sys/kernel/osrelease; then
    if [[ ! -s "$token_file" ]]; then
      log "Work mode needs a 1Password service account token in $token_file (see README)"
      exit 1
    fi
    OP_SERVICE_ACCOUNT_TOKEN="$(<"$token_file")"
    export OP_SERVICE_ACCOUNT_TOKEN
    if ! command -v op >/dev/null; then
      log "Installing 1Password CLI"
      arch="$(dpkg --print-architecture)"
      curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
        | sudo gpg --dearmor --yes --output /usr/share/keyrings/1password-archive-keyring.gpg
      echo "deb [arch=$arch signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$arch stable main" \
        | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
      sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq 1password-cli
    fi
  fi

  # 3. The repo itself.
  if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    log "Cloning $REPO"
    git clone --branch "$BRANCH" "$REPO" "$DOTFILES_DIR"
  fi

  # Leak guard: block commits that would publish work-sensitive strings.
  git -C "$DOTFILES_DIR" config core.hooksPath .githooks

  # 4. Packages first, so tools the templates need at render time (1Password's
  #    `op` on macOS) exist before chezmoi evaluates them.
  log "Installing packages (this takes a while on a fresh machine)"
  brew bundle install --file="$DOTFILES_DIR/Brewfile" || log "Some Brewfile entries failed; continuing"
  if [[ "$os" == "Darwin" ]]; then
    brew bundle install --file="$DOTFILES_DIR/Brewfile.mac" || log "Some Brewfile.mac entries failed; continuing"
  fi
  if [[ "${DOTFILES_WORK:-0}" == "1" ]]; then
    brew bundle install --file="$DOTFILES_DIR/Brewfile.work" || log "Some Brewfile.work entries failed; continuing"
  fi

  # 5. Render dotfiles and run the setup scripts.
  log "Applying dotfiles with chezmoi"
  chezmoi init --apply --source "$DOTFILES_DIR"

  log "Done. Open a new terminal (or run: exec zsh)."
}

main "$@"
