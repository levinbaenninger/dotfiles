#!/usr/bin/env bash
# Keep the Azure DevOps PAT in 1Password (Work/dotfiles, field ado_pat) alive.
#
# Runs on the managed work laptop (WSL), the only place where `az login` passes
# the company's Conditional Access. A weekly systemd timer calls it; run it by
# hand with --force to renew now, or --check to only report.
#
#   1. Find the PAT by display name ($ADO_PAT_NAME, default "dotfiles").
#   2. More than $ADO_PAT_RENEW_DAYS (30) days left: nothing to do.
#   3. Otherwise extend it to $ADO_PAT_LIFETIME_DAYS (365). Same token value,
#      so nothing else changes.
#   4. If extending fails (e.g. org lifetime policy): create a new PAT with the
#      same scopes, store it in 1Password, push it to $ADO_PAT_PUSH_HOSTS and
#      revoke the old one.
#
# The result goes to ~/.local/state/dotfiles/ado-pat.status; zsh shows it at
# startup when something needs attention.
set -euo pipefail

NAME="${ADO_PAT_NAME:-dotfiles}"
RENEW_DAYS="${ADO_PAT_RENEW_DAYS:-30}"
LIFETIME_DAYS="${ADO_PAT_LIFETIME_DAYS:-365}"
PUSH_HOSTS="${ADO_PAT_PUSH_HOSTS:-}"
SCOPES="${ADO_PAT_SCOPES:-vso.code_write vso.work_write vso.build vso.project vso.wiki_write vso.packaging}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
STATUS_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/ado-pat.status"
API_BASE="${ADO_PAT_API_BASE:-https://vssps.dev.azure.com}" # overridable for tests
API_VERSION="7.1-preview.1"
ADO_RESOURCE="499b84ac-1321-427f-aa17-267ca6975798" # Azure DevOps' Entra app ID

mode="renew-if-needed"
case "${1:-}" in
  --force) mode="force" ;;
  --check) mode="check" ;;
  "") ;;
  *) echo "usage: $0 [--check|--force]" >&2; exit 2 ;;
esac

mkdir -p "$(dirname "$STATUS_FILE")"
status() { # status <ok|warn|error> <message>
  printf '%s %s %s\n' "$(date -u +%FT%TZ)" "$1" "$2" > "$STATUS_FILE"
  echo "$2"
}
die() { status error "ado-pat: $*"; exit 1; }

OP="${OP:-$(command -v op || command -v op.exe || true)}"

# ADO_ORG comes from the rendered work.env (1Password Work/dotfiles).
# shellcheck disable=SC1091
[[ -f "$HOME/.config/dotfiles/work.env" ]] && . "$HOME/.config/dotfiles/work.env"
[[ -n "${ADO_ORG:-}" ]] || die "ADO_ORG unknown; is this a work machine (chezmoi work = true)?"

entra=$(az account get-access-token --resource "$ADO_RESOURCE" --query accessToken -o tsv 2>/dev/null) \
  || die "Azure CLI not signed in; run: az login"

api() { # api <METHOD> [json-body] -> response body on stdout
  local method="$1" body="${2:-}" url="$API_BASE/$ADO_ORG/_apis/tokens/pats?api-version=$API_VERSION"
  [[ "$method" == GET* ]] && { url="$url&${method#GET }"; method=GET; }
  local args=(-sS -X "$method" -H "Authorization: Bearer $entra" -H "Content-Type: application/json" -w '\n%{http_code}')
  [[ -n "$body" ]] && args+=(--data "$body")
  local out code
  out=$(curl "${args[@]}" "$url") || die "request to Azure DevOps failed"
  code=${out##*$'\n'}; out=${out%$'\n'*}
  [[ "$code" == 2* ]] || { echo "$out" >&2; die "Azure DevOps API returned HTTP $code ($method)"; }
  printf '%s' "$out"
}

# 1. Find the PAT by name among active PATs (the API pages its results).
current="" continuation=""
while :; do
  page=$(api "GET displayFilterOption=active${continuation:+&continuationToken=$continuation}")
  current=$(jq -c --arg n "$NAME" '[.patTokens[] | select(.displayName == $n)] | sort_by(.validTo) | last // empty' <<<"$page")
  [[ -n "$current" ]] && break
  continuation=$(jq -r '.continuationToken // empty' <<<"$page")
  [[ -n "$continuation" ]] || break
done
[[ -n "$current" ]] || die "no active PAT named \"$NAME\"; rename yours in Azure DevOps or set ADO_PAT_NAME"

auth_id=$(jq -r .authorizationId <<<"$current")
valid_to=$(jq -r .validTo <<<"$current")
days_left=$(( ($(date -d "$valid_to" +%s) - $(date +%s)) / 86400 ))

# 2. Nothing to do yet?
if [[ "$mode" == "check" || ( "$mode" == "renew-if-needed" && "$days_left" -gt "$RENEW_DAYS" ) ]]; then
  status ok "ado-pat: \"$NAME\" valid for $days_left more days (until ${valid_to%%T*})"
  exit 0
fi

new_valid_to=$(date -u -d "+$LIFETIME_DAYS days" +%Y-%m-%dT%H:%M:%S.000Z)
scope=$(jq -r .scope <<<"$current")

# 3. Extend the existing PAT: same value, so no redistribution.
update=$(jq -nc --arg id "$auth_id" --arg n "$NAME" --arg s "$scope" --arg v "$new_valid_to" \
  '{authorizationId: $id, displayName: $n, scope: $s, validTo: $v, allOrgs: false}')
if result=$(api PUT "$update" 2>/dev/null) && [[ "$(jq -r '.patTokenError // "none"' <<<"$result")" == "none" ]]; then
  status ok "ado-pat: extended \"$NAME\" to $(jq -r '.patToken.validTo' <<<"$result" | cut -dT -f1) (was $days_left days left)"
  exit 0
fi

# 4. Extending wasn't allowed: create a replacement with the same scopes.
[[ -n "$OP" ]] || die "extending failed and 1Password CLI (op/op.exe) is missing, can't store a new PAT"
create=$(jq -nc --arg n "$NAME" --arg s "${scope:-$SCOPES}" --arg v "$new_valid_to" \
  '{displayName: $n, scope: $s, validTo: $v, allOrgs: false}')
result=$(api POST "$create")
[[ "$(jq -r '.patTokenError // "none"' <<<"$result")" == "none" ]] \
  || die "creating a new PAT failed: $(jq -r .patTokenError <<<"$result")"
token=$(jq -r '.patToken.token' <<<"$result")
[[ -n "$token" && "$token" != null ]] || die "Azure DevOps returned no token"

"$OP" item edit dotfiles --vault Work "ado_pat[password]=$token" >/dev/null \
  || die "new PAT created but storing it in 1Password failed; revoke it in Azure DevOps and retry"
unset token

# Re-render this machine's work files, then update the headless work VMs.
command -v chezmoi >/dev/null && chezmoi apply --force "$HOME/.config/dotfiles/work.env" "$HOME/.npmrc" >/dev/null 2>&1 || true
failed_hosts=()
for host in $PUSH_HOSTS; do
  OP="$OP" "$DOTFILES_DIR/scripts/push-work-secrets.sh" "$host" >/dev/null 2>&1 || failed_hosts+=("$host")
done

# Revoke the old PAT only once the new one is stored.
curl -sS -o /dev/null -X DELETE -H "Authorization: Bearer $entra" \
  "$API_BASE/$ADO_ORG/_apis/tokens/pats?authorizationId=$auth_id&api-version=$API_VERSION" || true

if ((${#failed_hosts[@]})); then
  status warn "ado-pat: new PAT stored in 1Password; push failed for: ${failed_hosts[*]} (run scripts/push-work-secrets.sh <host>)"
else
  status ok "ado-pat: replaced \"$NAME\" (valid until ${new_valid_to%%T*}); pushed to: ${PUSH_HOSTS:-no hosts}"
fi
