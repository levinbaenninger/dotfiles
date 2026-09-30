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
{{- if not .work }}
- GitHub: `gh` is logged in and is git's credential helper; use normal `github.com` URLs.
{{- end }}
{{- if .work }}
- Dev servers: use one of the ports {{ join ", " .fleet.ports }}. The user's work laptop forwards these to its own localhost over SSH, so give the user `http://localhost:<port>/` and pass it as `url` in the T3 Code preview (the preview runs on the laptop; the `environment-port` target fails here). `https://{{ .chezmoi.hostname }}.exe.xyz:<port>/` doesn't load there: its network blocks every port but 443 and SSH.
{{- else }}
- Dev servers: listen on `0.0.0.0` with a port between 3000 and 9999, then give the user `https://{{ .chezmoi.hostname }}.exe.xyz:<port>/` (private to the user; exe.dev handles TLS). Vite needs `server.allowedHosts: ['.exe.xyz']`, Next.js `allowedDevOrigins`.
{{- end }}
- To check a dev server from this VM (curl, Playwright, Chrome DevTools), use `http://localhost:<port>/`. The `.exe.xyz` name resolves to the VM itself here and skips the proxy.
{{- if .work }}
- Work machine. Azure DevOps (git over HTTPS and the ADO MCP server) authenticates with the PAT from 1Password (`ADO_PAT` in `~/.config/dotfiles/work.env`). Never print, log or commit it. If access fails, the PAT is likely expired: ask the user to renew it (see the dotfiles README).
{{- end }}
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
