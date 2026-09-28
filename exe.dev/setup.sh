#!/bin/bash
# exe.dev first-boot script: runs once as `exedev` via /exe.dev/setup.
# Kept tiny on purpose (setup scripts have a size limit); install.sh does the work.
#
# Make it the default for every new VM:
#   ssh exe.dev defaults write dev.exe new.setup-script < ~/dotfiles/exe.dev/setup.sh
# Or for a single VM:
#   ssh exe.dev new --setup-script /dev/stdin < ~/dotfiles/exe.dev/setup.sh
#
# Progress: ssh <vm>.exe.xyz tail -f dotfiles-setup.log
set -euo pipefail
export DOTFILES_PROFILE=exe DOTFILES_WORK=0
curl -fsSL https://raw.githubusercontent.com/levinbaenninger/dotfiles/main/install.sh \
  | bash >"$HOME/dotfiles-setup.log" 2>&1
