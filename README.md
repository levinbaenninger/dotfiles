# Dotfiles

One setup for macOS, WSL at work and Linux servers. Managed with
[chezmoi](https://chezmoi.io), packages from Homebrew (on Linux too), and work
secrets from 1Password.

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
| `linux` | anything else | headless, no signing |

Override with `DOTFILES_PROFILE=…`, `DOTFILES_WORK=1|0` and
`DOTFILES_CONTAINER_RUNTIME=docker|podman` (WSL defaults to podman). You're asked
"work machine?" once on interactive installs; the answer is stored in
`~/.config/chezmoi/chezmoi.toml`.

### R2-D2 on Hetzner

The server currently resolves as `devbox-01` on Tailscale and logs in as
`levin`. The macOS SSH config adds `r2d2` as an alias for that target. The shell
prompt and Claude status line display `R2-D2` for either hostname. Set the
server's pretty hostname to `R2-D2` for the same name in T3 Connect without
changing its Tailscale address:

```bash
chezmoi apply ~/.ssh/config
ssh r2d2 hostname
ssh -t r2d2 'sudo hostnamectl set-hostname --pretty "R2-D2"'
```

This is one machine for personal and work projects. Run chezmoi with
`DOTFILES_WORK=1`. Personal Git identity stays the default; repositories under
`~/work/` and Azure DevOps remotes use the work identity. Work mode is a
machine-wide setting, so the work agent integrations and work secrets are also
available from personal project sessions. Use a separate machine or account
if those need strict isolation.

Before the first install, copy the `Work/dotfiles` 1Password item from the Mac
to `~/.config/dotfiles/work-secrets.json` on the server. This sends the item,
including PATs, to the server over Tailscale SSH and stores it with mode 0600:

```bash
scripts/push-work-secrets.sh r2d2
ssh -t r2d2 'DOTFILES_WORK=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/levinbaenninger/dotfiles/main/install.sh)"'
```

The install needs the server user's sudo password for Ubuntu prerequisites,
Homebrew and the login shell. On later runs, `chezmoi update` pulls and applies
dotfile changes. Re-run `scripts/push-work-secrets.sh r2d2` after editing the
1Password item. The work laptop's PAT renewal timer targets
`levin@devbox-01` over Tailscale.

Install T3 Code on the server and link it to T3 Connect. Open the sign-in URL
printed by `t3 connect` on another device, confirm the code, and accept the
background service when prompted:

```bash
ssh r2d2 'curl -fsSL https://t3.codes/install.sh | sh'
ssh -t r2d2 '~/.local/bin/t3 connect --headless'
ssh r2d2 '~/.local/bin/t3 connect status && ~/.local/bin/t3 service status'
```

The service needs systemd lingering to stay up after logout. If T3 reports
`linger-disabled`, run `ssh -t r2d2 'sudo loginctl enable-linger levin'` and
then `ssh r2d2 '~/.local/bin/t3 service install'`. Sign in to the same T3
Connect account in the client and select this environment. See the
[T3 remote access](https://github.com/pingdotgg/t3code/blob/main/docs/user/remote-access.md)
and [background service](https://github.com/pingdotgg/t3code/blob/main/docs/user/background-service.md)
guides.

**Dev servers from the work laptop:** `chezmoi apply` on WSL enables
`dev-tunnel.service`. It forwards the ports in `fleet.ports` from R2-D2 to the
laptop's localhost over SSH. Listen on `127.0.0.1` on the server and open
`http://localhost:<port>/` on the laptop, including in T3 Code preview.

- WSL's `ssh` needs a key accepted by the Hetzner server without a prompt.
  Check with `env -i HOME="$HOME" ssh -o BatchMode=yes levin@devbox-01 true`
  in WSL. Add that user's public key to the server's `~/.ssh/authorized_keys`
  if needed.
- Keep WSL running for the tunnel. Check it with
  `systemctl --user status dev-tunnel`.
- A port already in use in WSL is skipped. Stop the local server and run
  `systemctl --user restart dev-tunnel` to get it back.

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
  `ado_org`, `sonarqube_url`, `sonarqube_token`, `npm_feeds`, and `ado_pat`
  (one PAT for git, the ADO MCP server and npm) or `npm_pat` (npm only).
- `Brewfile.work` adds work-only packages (Azure CLI).
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

**Headless Linux work hosts:** there's no 1Password app, so the Mac pushes a
copy of the `Work/dotfiles` item to the host
(`~/.config/dotfiles/work-secrets.json`, mode 0600) and chezmoi reads it from
there:

```bash
scripts/push-work-secrets.sh r2d2          # on the Mac; re-run after changing a value
ssh r2d2 'DOTFILES_WORK=1 ~/dotfiles/install.sh'   # after cloning, if needed
```

Azure DevOps git access, the ADO MCP server and the npm feeds use one PAT,
field `ado_pat` in `Work/dotfiles`: the company's Conditional Access blocks
`az login` from non-managed devices. Scopes: **Code** (Read & write),
**Work Items** (Read & write), **Build** (Read), **Project and Team** (Read),
**Wiki** (Read & write), **Packaging** (Read). Without `ado_pat`, git and the
MCP server fall back to `az login` and npm to `npm_pat`.

**Renewal is automatic** on the WSL work laptop, the only machine where
`az login` is allowed. A weekly systemd timer runs `scripts/renew-ado-pat.sh`:

- more than 30 days left: nothing happens;
- otherwise it extends the PAT by a year (same value, nothing to redistribute);
- if the org doesn't allow extending, it creates a new PAT with the same
  scopes, stores it in `ado_pat`, pushes it to the work hosts (`work:` in
  `.chezmoidata/fleet.yaml`) and revokes the old one.

Problems (e.g. an expired `az login`) show up as a warning when a new shell
starts. By hand: `scripts/renew-ado-pat.sh --check` (report only) or `--force`.
The PAT must be named `dotfiles` in Azure DevOps (or set `ADO_PAT_NAME`).

Setup on the laptop (once): WSL with systemd (`/etc/wsl.conf`: `[boot]`
`systemd=true`), `az login`, and a working
`ssh -o BatchMode=yes levin@devbox-01 true` from WSL. `chezmoi apply` then
enables the timer.

The pushed file holds the same values the rendered work files (`work.env`,
`.npmrc`) contain anyway.

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
.githooks/pre-commit     leak guard
home/                    chezmoi source (see .chezmoiroot)
  .chezmoi.toml.tmpl     profile detection
  .chezmoidata/          agents.yaml (MCP, skills, agent settings)
  .chezmoiscripts/       brew bundle, Vite+/Claude/Codex, agent sync, login shell
  .chezmoitemplates/     agents.md (shared agent instructions), merge-into (settings merge)
  dot_zshrc.tmpl, dot_gitconfig.tmpl, dot_claude/, dot_codex/, dot_config/…
```
