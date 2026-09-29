#!/usr/bin/env bash
# Copy the 1Password item Work/dotfiles to a headless work VM, which has no
# 1Password app, then re-apply the dotfiles there. Run on the Mac:
#
#   scripts/push-work-secrets.sh c3po
#
# Re-run whenever a value in the item changes (e.g. a rotated npm_pat).
# The values are never printed; they travel over SSH into a 0600 file.
set -euo pipefail
host="${1:?usage: $0 <ssh-host>}"
# On WSL, 1Password's CLI and SSH agent live on the Windows side.
OP="${OP:-$(command -v op || command -v op.exe)}"
SSH="${SSH:-$(if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null && command -v ssh.exe >/dev/null; then echo ssh.exe; else echo ssh; fi)}"

json=$("$OP" item get dotfiles --vault Work --format json \
  | jq '[.fields[] | select(.label and .value and .label != "password" and .label != "notesPlain")
         | {(.label): .value}] | add')
[[ "$json" != "null" ]] || { echo "Work/dotfiles has no fields" >&2; exit 1; }

printf '%s\n' "$json" | "$SSH" "$host" \
  'umask 077 && mkdir -p ~/.config/dotfiles && cat > ~/.config/dotfiles/work-secrets.json'
echo "Pushed $(jq -r 'keys | join(", ")' <<<"$json") to $host."

# Apply if the VM is already in work mode; otherwise print the next step.
if "$SSH" "$host" 'grep -q "work = true" ~/.config/chezmoi/chezmoi.toml 2>/dev/null'; then
  "$SSH" "$host" 'zsh -lc "chezmoi apply"' && echo "Re-applied dotfiles on $host."
else
  echo "Next, on $host: DOTFILES_WORK=1 ~/dotfiles/install.sh"
fi
