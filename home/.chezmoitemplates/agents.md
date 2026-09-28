# Global agent instructions

Shared by Claude Code (~/.claude/CLAUDE.md) and Codex (~/.codex/AGENTS.md).
Source: ~/dotfiles/home/.chezmoitemplates/agents.md. Edit there, then `chezmoi apply`.

## Conventions

- Commit messages follow Conventional Commits: `<type>[optional scope]: <description>`.
- Open pull requests as drafts unless asked otherwise.

## This machine

{{ if eq .profile "mac" -}}
- macOS. Packages come from Homebrew (`~/dotfiles/Brewfile`, `Brewfile.mac`).
{{ else if eq .profile "wsl" -}}
- WSL on a work laptop. Packages come from Homebrew on Linux (`~/dotfiles/Brewfile`).
- Windows tools are reachable with the `.exe` suffix (e.g. `op.exe`, `ssh.exe`).
{{ else if eq .profile "exe" -}}
- An exe.dev VM (Ubuntu, user `exedev`, passwordless sudo). Packages come from Homebrew on Linux.
- exe.dev HTTPS proxy: https://exe.dev/docs/proxy.md. Only use documented exe.dev features (https://exe.dev/docs.md); undocumented local endpoints are internal and unstable.
- GitHub access goes through the exe.dev GitHub integration (`github.int.exe.xyz`), not a token on the VM.
{{ else -}}
- A Linux VM. Packages come from Homebrew on Linux (`~/dotfiles/Brewfile`).
{{ end -}}
- Node, npm, pnpm and bun are managed by Vite+ (`vp`). Don't install them another way.
{{- if eq .containerRuntime "podman" }}
- Containers run on **Podman**, not Docker. Use `podman` and `podman compose`.
  `docker` is a shim that forwards to `podman`, so Docker-style commands and
  scripts work, but there is no Docker daemon and no Docker Desktop.
{{- end }}
{{- $local := joinPath .chezmoi.homeDir ".config/dotfiles/agents.local.md" }}
{{- if stat $local }}

## Local notes

{{ include $local | trim }}
{{- end }}
