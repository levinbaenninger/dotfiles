# Dotfiles

One setup for every machine I work on: macOS, WSL at work, Linux VMs and
[exe.dev](https://exe.dev) VMs. Managed with [chezmoi](https://chezmoi.io),
packages from Homebrew (on Linux too), secrets from 1Password.

## Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/levinbaenninger/dotfiles/main/install.sh)"
```

`install.sh` installs Homebrew and the Brewfiles, clones this repo to
`~/dotfiles`, then runs `chezmoi init --apply`. It detects the machine type:

| Profile | Detected by | Differences |
| --- | --- | --- |
| `mac` | macOS | `Brewfile.mac` (apps, fonts), SSH via 1Password agent, commit signing |
| `wsl` | `microsoft` in the kernel release | `ssh.exe` + 1Password's WSL signer, work mode on by default |
| `exe` | `/exe.dev` exists | no signing, GitHub through the exe.dev integration |
| `linux` | anything else | no signing |

Override with `DOTFILES_PROFILE=…`, `DOTFILES_WORK=1|0` and
`DOTFILES_CONTAINER_RUNTIME=docker|podman` (work machines default to podman). You're asked
"work machine?" once on interactive installs; the answer is stored in
`~/.config/chezmoi/chezmoi.toml`.

### exe.dev

New VMs run [`exe.dev/setup.sh`](exe.dev/setup.sh) on first boot. It calls `install.sh`:

```bash
# default for every new VM
ssh exe.dev defaults write dev.exe new.setup-script < ~/dotfiles/exe.dev/setup.sh
# watch it
ssh <vm>.exe.xyz tail -f dotfiles-setup.log
```

If first boot gets too slow, build [`exe.dev/Dockerfile`](exe.dev/Dockerfile)
(exeuntu plus these dotfiles, no secrets) and use `ssh exe.dev new --image=…`.

Keep work secrets off exe.dev VMs. For tokens a VM needs, use exe.dev
[integrations](https://exe.dev/docs/integrations.md) (GitHub, HTTP proxy with
an injected header), so the credential stays on exe.dev's side.

## Day to day

```bash
chezmoi edit ~/.zshrc      # edit the source, not the rendered file
chezmoi diff               # what would change
chezmoi apply              # render + run changed setup scripts
chezmoi update             # git pull + apply
chezmoi re-add ~/.config/herdr/config.toml   # pull a changed plain file back
```

Brewfiles: edit `Brewfile` (portable CLI, every machine) or `Brewfile.mac`
(macOS formulae, apps, fonts), then `chezmoi apply` runs `brew bundle`.

## AI agents (Claude Code + Codex)

Both agents are configured from one place:

| What | Source | Ends up in |
| --- | --- | --- |
| Global instructions | `home/.chezmoitemplates/agents.md` | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` |
| MCP servers | `agents.mcp` in `home/.chezmoidata/agents.yaml` | Claude user scope (`claude mcp add-json`), `~/.codex/config.toml` |
| Skills | `agents.skills` | `~/.agents/skills` (Codex reads it), symlinked into `~/.claude/skills` |
| Claude plugins | `agents.claude.plugins` | `claude plugin install` |
| Settings | `agents.claude.settings`, `agents.codex.config` | merged into `settings.json` / `config.toml` |
| herdr hooks | – | `herdr integration install claude|codex` |

Machine-specific or private agent notes go in
`~/.config/dotfiles/agents.local.md` (untracked). If it exists, it's appended to
both instruction files. On podman machines both files also say "use podman".
`~/.local/bin/docker` forwards to `podman`, and `DOCKER_HOST` points at the
Podman socket (enable it once: `systemctl --user enable --now podman.socket`).

Both apps rewrite their own config files (project trust, UI state, plugin
caches), so settings are merged instead of overwritten. `defaults` only fill in
missing keys, so a change you make in the app sticks on that machine. `managed`
keys always win. To change a default everywhere, edit `agents.yaml`.

## Work config and secrets

Nothing company-specific is in this repo: no org names, URLs or tokens. Work
machines (`work = true`) read those values from 1Password when chezmoi renders
the templates:

- 1Password vault **Work**, item **dotfiles**, fields `git_name`, `git_email`,
  `ado_org`, `sonarqube_url`, `sonarqube_token`, `npm_pat`, `npm_feeds`. All
  must exist or the apply fails.
- They're rendered into `~/.config/dotfiles/work.env` (mode 0600) and
  `~/.config/git/work.gitconfig`. Nothing is rendered on personal machines.
- Work MCP servers source `work.env` when they start, so tokens never end up
  in `~/.claude.json`, `config.toml` or their backup copies.
- Git identities: personal by default. The work name/email (unsigned) applies to
  Azure DevOps remotes and to every repo under `~/work/` (`includeIf` in
  `~/.gitconfig`). Check with `git config user.email` inside a repo.

### Azure Artifacts (npm)

On work machines `~/.npmrc` (0600) holds credentials for every feed in
`npm_feeds` (comma/space separated, `feed` for org-scoped feeds or
`project/feed`). The token is `npm_pat`, an Azure DevOps PAT with
**Packaging (Read)** scope; use Read & write if you publish. Projects keep their
own `.npmrc` with `registry=…`; npm, pnpm and bun (via Vite+) all pick up the
credentials. To rotate the PAT or add a feed, edit the 1Password item and run
`chezmoi apply`. This replaces `better-vsts-npm-auth`.

To add a work secret: add a field to the 1Password item, reference it in
`home/dot_config/dotfiles/private_work.env.tmpl` with
`onepasswordRead "op://Work/dotfiles/<field>"`, and use `$VAR` wherever you need it.

**WSL prerequisites:** 1Password for Windows with the
[WSL integration](https://developer.1password.com/docs/ssh/integrations/wsl/)
and CLI integration turned on. chezmoi calls `op.exe` when there's no Linux
`op`, and git signs through `op-ssh-sign-wsl.exe`.

### Leak guard

```bash
git config core.hooksPath .githooks
```

The pre-commit hook rejects staged changes containing any value from
`~/.config/dotfiles/work.env` or from `~/.config/dotfiles/forbidden-words`
(untracked, one string per line: put your company and org names there on
machines without work.env). Then it runs `ggshield` if you're logged in.

## Layout

```
install.sh               bootstrap (all platforms)
Brewfile                 portable CLI tools
Brewfile.mac             macOS formulae, apps, fonts
exe.dev/                 setup script + optional image
.githooks/pre-commit     leak guard
home/                    chezmoi source (see .chezmoiroot)
  .chezmoi.toml.tmpl     profile detection
  .chezmoidata/          agents.yaml (MCP, skills, agent settings)
  .chezmoiscripts/       brew bundle, Vite+/Claude/Codex, agent sync, login shell
  .chezmoitemplates/     agents.md (shared agent instructions), merge-into (settings merge)
  dot_zshrc.tmpl, dot_gitconfig.tmpl, dot_claude/, dot_codex/, dot_config/…
```
