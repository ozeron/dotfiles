#!/usr/bin/env bash
set -euo pipefail

CODEX_DIR="${CODEX_DIR:-$HOME/.codex}"
PROFILES_DIR="$CODEX_DIR/profiles"
DEFAULT_VAULT_ID="7dspguroi747r2ylx4wasz2kpm"
ITEM_PREFIX="codex/"
ITEM_TAG="codex-profile"

VAULT_ID="${CODEX_PROFILE_VAULT_ID:-$DEFAULT_VAULT_ID}"

require_command() {
  local name=$1

  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Error: required command '$name' is not available." >&2
    exit 1
  fi
}

require_runtime() {
  require_command jq
  require_command op

  if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
    echo "Error: OP_SERVICE_ACCOUNT_TOKEN is not set in the environment." >&2
    exit 1
  fi
}

validate_profile_name() {
  local name=$1
  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]]
}

profile_title() {
  local name=$1
  printf '%s%s\n' "$ITEM_PREFIX" "$name"
}

profile_name_from_title() {
  local title=$1
  printf '%s\n' "${title#"$ITEM_PREFIX"}"
}

get_account_id_from_file() {
  local file=$1
  [ -f "$file" ] || return 1
  jq -r '.tokens.account_id // empty' "$file" 2>/dev/null
}

get_current_account_id() {
  get_account_id_from_file "$CODEX_DIR/auth.json"
}

op_item_list_json() {
  op item list --vault "$VAULT_ID" --tags "$ITEM_TAG" --format json
}

remote_item_count() {
  op_item_list_json | jq 'length'
}

remote_title_exists() {
  local title=$1

  op_item_list_json | jq -e --arg title "$title" '.[] | select(.title == $title)' >/dev/null
}

remote_item_id_by_title() {
  local title=$1

  op_item_list_json | jq -r --arg title "$title" '[.[] | select(.title == $title) | .id][0] // empty'
}

remote_item_json_by_id() {
  local item_id=$1
  op item get "$item_id" --vault "$VAULT_ID" --format json
}

remote_item_account_id() {
  jq -r '[.fields[]? | select(.id == "account_id" or .label == "account_id") | .value][0] // empty'
}

remote_item_notes_plain() {
  jq -r '.notesPlain // ([.fields[]? | select(.id == "notesPlain" or .label == "notesPlain") | .value][0] // empty)'
}

remote_profile_name_by_account_id() {
  local account_id=$1
  local item_ids
  local item_id
  local item_json
  local item_account_id
  local title

  [ -n "$account_id" ] || return 0

  item_ids="$(op_item_list_json | jq -r 'sort_by(.title)[]?.id')"
  while IFS= read -r item_id; do
    [ -n "$item_id" ] || continue
    item_json="$(remote_item_json_by_id "$item_id")"
    item_account_id="$(printf '%s\n' "$item_json" | remote_item_account_id)"
    if [ "$item_account_id" = "$account_id" ]; then
      title="$(printf '%s\n' "$item_json" | jq -r '.title // empty')"
      profile_name_from_title "$title"
      return 0
    fi
  done <<<"$item_ids"
}

current_profile_name() {
  local account_id

  account_id="$(get_current_account_id || true)"
  [ -n "$account_id" ] || return 0
  remote_profile_name_by_account_id "$account_id"
}

local_profile_names() {
  if [ ! -d "$PROFILES_DIR" ]; then
    return 0
  fi

  find "$PROFILES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort
}

local_profile_name_by_account_id() {
  local account_id=$1
  local name
  local profile_account_id

  [ -n "$account_id" ] || return 0

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    profile_account_id="$(get_account_id_from_file "$PROFILES_DIR/$name/auth.json" || true)"
    if [ -n "$profile_account_id" ] && [ "$profile_account_id" = "$account_id" ]; then
      printf '%s\n' "$name"
      return 0
    fi
  done < <(local_profile_names)
}

prompt_yes_no() {
  local prompt=$1
  local answer

  while true; do
    printf '%s [y/N]: ' "$prompt" >&2
    if ! IFS= read -r answer; then
      echo "Error: failed to read confirmation response." >&2
      exit 1
    fi
    case "$answer" in
      y|Y|yes|YES)
        return 0
        ;;
      ""|n|N|no|NO)
        return 1
        ;;
      *)
        echo "Please answer y or n." >&2
        ;;
    esac
  done
}

prompt_for_profile_name() {
  local prompt=$1
  local name

  while true; do
    printf '%s: ' "$prompt" >&2
    if ! IFS= read -r name; then
      echo "Error: failed to read profile name." >&2
      exit 1
    fi
    if ! validate_profile_name "$name"; then
      echo "Error: Invalid profile name '$name'. Allowed: letters, numbers, ., _, -" >&2
      continue
    fi
    printf '%s\n' "$name"
    return 0
  done
}

upsert_remote_profile() {
  local name=$1
  local auth_file=$2
  local title
  local account_id=""
  local auth_payload=""
  local item_id=""

  title="$(profile_title "$name")"
  if [ -f "$auth_file" ]; then
    auth_payload="$(jq -c . "$auth_file" 2>/dev/null || cat "$auth_file")"
    account_id="$(get_account_id_from_file "$auth_file" || true)"
  fi

  item_id="$(remote_item_id_by_title "$title")"
  if [ -n "$item_id" ]; then
    op item edit "$item_id" \
      --vault "$VAULT_ID" \
      --tags "$ITEM_TAG" \
      "profile_name[text]=$name" \
      "account_id[text]=$account_id" \
      "notesPlain=$auth_payload" >/dev/null
  else
    op item create \
      --vault "$VAULT_ID" \
      --category "Secure Note" \
      --title "$title" \
      --tags "$ITEM_TAG" \
      "profile_name[text]=$name" \
      "account_id[text]=$account_id" \
      "notesPlain=$auth_payload" >/dev/null
  fi
}

write_auth_payload() {
  local auth_payload=$1
  local tmp_file

  mkdir -p "$CODEX_DIR"
  tmp_file="$(mktemp "$CODEX_DIR/.auth.tmp.XXXXXX")"
  printf '%s' "$auth_payload" >"$tmp_file"
  mv "$tmp_file" "$CODEX_DIR/auth.json"
}

clear_current() {
  rm -f "$CODEX_DIR/auth.json"
  echo "Current auth cleared (Logged out)."
}

maybe_migrate_local_profiles() {
  local remote_count
  local local_names=()
  local current_auth_exists=0
  local current_account_id=""
  local matched_local_name=""
  local import_current_name=""
  local name
  local auth_file

  remote_count="$(remote_item_count)"
  if [ "$remote_count" -gt 0 ]; then
    return 0
  fi

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    local_names+=("$name")
  done < <(local_profile_names)

  if [ -f "$CODEX_DIR/auth.json" ]; then
    current_auth_exists=1
    current_account_id="$(get_current_account_id || true)"
    matched_local_name="$(local_profile_name_by_account_id "$current_account_id" || true)"
  fi

  if [ "${#local_names[@]}" -eq 0 ] && [ "$current_auth_exists" -eq 0 ]; then
    return 0
  fi

  echo "No Codex profiles found in 1Password for vault '$VAULT_ID'."
  if [ "${#local_names[@]}" -gt 0 ]; then
    echo "Local profiles to import:"
    for name in "${local_names[@]}"; do
      echo "  - $name"
    done
  fi

  if [ "$current_auth_exists" -eq 1 ]; then
    if [ -n "$matched_local_name" ]; then
      echo "Current auth matches local profile '$matched_local_name'."
    else
      import_current_name="$(prompt_for_profile_name "Enter a profile name for the current active auth")"
      echo "Current auth will also be imported as '$import_current_name'."
    fi
  fi

  if ! prompt_yes_no "Import these profiles into 1Password now?"; then
    echo "Migration canceled."
    exit 1
  fi

  for name in "${local_names[@]}"; do
    if [ "$current_auth_exists" -eq 1 ] && [ -n "$matched_local_name" ] && [ "$name" = "$matched_local_name" ]; then
      auth_file="$CODEX_DIR/auth.json"
    else
      auth_file="$PROFILES_DIR/$name/auth.json"
    fi
    upsert_remote_profile "$name" "$auth_file"
  done

  if [ -n "$import_current_name" ]; then
    upsert_remote_profile "$import_current_name" "$CODEX_DIR/auth.json"
  fi
}

ensure_backend_ready() {
  require_runtime
  maybe_migrate_local_profiles
}

list_profiles() {
  local items_json
  local current_name
  local line
  local title
  local name

  items_json="$(op_item_list_json)"
  if [ "$(printf '%s\n' "$items_json" | jq 'length')" -eq 0 ]; then
    echo "No profiles found."
    return 0
  fi

  current_name="$(current_profile_name || true)"

  echo "Available profiles:"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    title="$line"
    name="$(profile_name_from_title "$title")"
    if [ -n "$current_name" ] && [ "$name" = "$current_name" ]; then
      echo "* $name (active)"
    else
      echo "  $name"
    fi
  done < <(printf '%s\n' "$items_json" | jq -r 'sort_by(.title)[] | .title')
}

save_profile() {
  local name=$1

  if [ -z "$name" ]; then
    echo "Usage: codex-profile save <name>"
    return 1
  fi
  if ! validate_profile_name "$name"; then
    echo "Error: Invalid profile name '$name'. Allowed: letters, numbers, ., _, -"
    return 1
  fi
  if [ ! -f "$CODEX_DIR/auth.json" ]; then
    echo "Error: Nothing to save (missing $CODEX_DIR/auth.json)."
    return 1
  fi

  upsert_remote_profile "$name" "$CODEX_DIR/auth.json"
  echo "Current auth saved to profile '$name'."
}

save_current_auth_before_mutation() {
  local current_name

  if [ ! -f "$CODEX_DIR/auth.json" ]; then
    return 0
  fi

  current_name="$(current_profile_name || true)"
  if [ -n "$current_name" ]; then
    echo "Autosaving current auth to profile '$current_name'..."
    upsert_remote_profile "$current_name" "$CODEX_DIR/auth.json"
    return 0
  fi

  current_name="$(prompt_for_profile_name "Current auth is not mapped to a profile. Enter a profile name to save it")"
  echo "Saving current auth to profile '$current_name'..."
  upsert_remote_profile "$current_name" "$CODEX_DIR/auth.json"
}

switch_profile() {
  local name=$1
  local title
  local item_id
  local item_json
  local auth_payload

  if [ -z "$name" ]; then
    echo "Usage: codex-profile switch <name>"
    return 1
  fi
  if ! validate_profile_name "$name"; then
    echo "Error: Invalid profile name '$name'. Allowed: letters, numbers, ., _, -"
    return 1
  fi

  title="$(profile_title "$name")"
  item_id="$(remote_item_id_by_title "$title")"
  if [ -z "$item_id" ]; then
    echo "Error: Profile '$name' not found."
    return 1
  fi

  save_current_auth_before_mutation

  item_json="$(remote_item_json_by_id "$item_id")"
  auth_payload="$(printf '%s\n' "$item_json" | remote_item_notes_plain)"
  if [ -n "$auth_payload" ]; then
    write_auth_payload "$auth_payload"
  else
    rm -f "$CODEX_DIR/auth.json"
  fi

  echo "Switched to profile '$name'."
}

show_help() {
  echo "Codex Profile Switcher"
  echo ""
  echo "Manage multiple Codex authentication profiles."
  echo ""
  echo "Usage: codex-profile <command> [arguments]"
  echo ""
  echo "Commands:"
  echo "  list                      List all available profiles and show the active one."
  echo "  save <name>               Save the current auth to a profile named <name>."
  echo "  switch <name>             Switch to the profile named <name>."
  echo "  clear                     Clear the current active auth (logout)."
  echo "  help, -h, --help          Show this help message."
  echo ""
}

case "${1:-}" in
  list)
    ensure_backend_ready
    list_profiles
    ;;
  save)
    ensure_backend_ready
    save_profile "${2:-}"
    ;;
  switch)
    ensure_backend_ready
    switch_profile "${2:-}"
    ;;
  clear)
    clear_current
    ;;
  help|-h|--help)
    show_help
    ;;
  *)
    show_help
    exit 1
    ;;
esac
