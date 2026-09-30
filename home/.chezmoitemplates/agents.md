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
{{ else -}}
- Linux server. Packages come from Homebrew on Linux (`~/dotfiles/Brewfile`).
{{- if .work }}
- Dev servers: listen on localhost on one of the ports {{ join ", " .fleet.ports }}. The work laptop forwards these ports over SSH, so give the user `http://localhost:<port>/` for its browser or T3 Code preview. Check the server locally at the same URL.
- Azure DevOps (git over HTTPS and the ADO MCP server) uses the PAT in `~/.config/dotfiles/work.env`. Never print, log or commit it. If access fails, check the PAT renewal steps in the dotfiles README.
{{- end }}
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
