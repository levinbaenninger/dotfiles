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
- GitHub goes through the exe.dev GitHub integration; there is no GitHub token on the VM. Use normal `github.com` URLs: git rewrites them for {{ range $i, $o := .github.owners }}{{ if $i }}, {{ end }}`{{ $o }}`{{ end }} repos, and `gh` uses `GH_HOST=github.int.exe.xyz`. If access fails, the repo needs an integration (`ssh exe.dev integrations add github ...`); ask the user.
- Dev servers: listen on `0.0.0.0` with a port between 3000 and 9999, then open `https://{{ .chezmoi.hostname }}.exe.xyz:<port>/` (private to the user; exe.dev handles TLS). Vite needs `server.allowedHosts: ['.exe.xyz']`, Next.js `allowedDevOrigins`.
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
