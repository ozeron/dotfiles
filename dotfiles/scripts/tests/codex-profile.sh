#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

STUB_BIN="$TMPDIR/bin"
mkdir -p "$STUB_BIN"

cat >"$STUB_BIN/op" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

state_dir="${CODEX_PROFILE_TEST_STATE_DIR:?missing state dir}"
items_file="$state_dir/items.json"
log_file="$state_dir/op.log"
mkdir -p "$state_dir"
[ -f "$items_file" ] || printf '[]\n' >"$items_file"

printf '%s\n' "$*" >>"$log_file"

build_item() {
  local id=$1
  local title=$2
  local tags=$3
  local profile_name=$4
  local account_id=$5
  local notes_plain=$6

  jq -n \
    --arg id "$id" \
    --arg title "$title" \
    --arg tags "$tags" \
    --arg profile_name "$profile_name" \
    --arg account_id "$account_id" \
    --arg notes_plain "$notes_plain" \
    '{
      id: $id,
      title: $title,
      tags: ($tags | split(",") | map(select(length > 0))),
      notesPlain: $notes_plain,
      fields: [
        {id: "profile_name", label: "profile_name", value: $profile_name},
        {id: "account_id", label: "account_id", value: $account_id},
        {id: "notesPlain", label: "notesPlain", value: $notes_plain}
      ]
    }'
}

parse_assignment() {
  local assignment=$1
  local key=${assignment%%=*}
  local value=${assignment#*=}

  case "$key" in
    "profile_name[text]")
      printf 'profile_name=%s\n' "$value"
      ;;
    "account_id[text]")
      printf 'account_id=%s\n' "$value"
      ;;
    "notesPlain")
      printf 'notes_plain=%s\n' "$value"
      ;;
  esac
}

case "${1:-} ${2:-}" in
  "item list")
    cat "$items_file"
    ;;
  "item get")
    target="${3:?missing item target}"
    jq -cer --arg target "$target" 'map(select(.id == $target or .title == $target))[0]' "$items_file"
    ;;
  "item create")
    shift 2
    title=""
    tags=""
    profile_name=""
    account_id=""
    notes_plain=""

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --title)
          title=$2
          shift 2
          ;;
        --tags)
          tags=$2
          shift 2
          ;;
        --vault|--category)
          shift 2
          ;;
        *)
          while IFS='=' read -r key value; do
            case "$key" in
              profile_name)
                profile_name=$value
                ;;
              account_id)
                account_id=$value
                ;;
              notes_plain)
                notes_plain=$value
                ;;
            esac
          done < <(parse_assignment "$1")
          shift
          ;;
      esac
    done

    next_id="item-$(( $(jq 'length' "$items_file") + 1 ))"
    item_json="$(build_item "$next_id" "$title" "$tags" "$profile_name" "$account_id" "$notes_plain")"
    tmp_file="$(mktemp "$state_dir/items.XXXXXX")"
    jq --argjson item "$item_json" '. + [$item]' "$items_file" >"$tmp_file"
    mv "$tmp_file" "$items_file"
    printf '%s\n' "$item_json"
    ;;
  "item edit")
    shift 2
    item_id="${1:?missing item id}"
    shift
    title=""
    tags=""
    profile_name=""
    account_id=""
    notes_plain=""

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --title)
          title=$2
          shift 2
          ;;
        --tags)
          tags=$2
          shift 2
          ;;
        --vault)
          shift 2
          ;;
        *)
          while IFS='=' read -r key value; do
            case "$key" in
              profile_name)
                profile_name=$value
                ;;
              account_id)
                account_id=$value
                ;;
              notes_plain)
                notes_plain=$value
                ;;
            esac
          done < <(parse_assignment "$1")
          shift
          ;;
      esac
    done

    tmp_file="$(mktemp "$state_dir/items.XXXXXX")"
    jq \
      --arg item_id "$item_id" \
      --arg title "$title" \
      --arg tags "$tags" \
      --arg profile_name "$profile_name" \
      --arg account_id "$account_id" \
      --arg notes_plain "$notes_plain" \
      '
      map(
        if .id == $item_id then
          .title = (if $title == "" then .title else $title end) |
          .tags = (if $tags == "" then .tags else ($tags | split(",") | map(select(length > 0))) end) |
          .notesPlain = $notes_plain |
          .fields = [
            {id: "profile_name", label: "profile_name", value: $profile_name},
            {id: "account_id", label: "account_id", value: $account_id},
            {id: "notesPlain", label: "notesPlain", value: $notes_plain}
          ]
        else
          .
        end
      )
      ' "$items_file" >"$tmp_file"
    mv "$tmp_file" "$items_file"
    jq -cer --arg item_id "$item_id" 'map(select(.id == $item_id))[0]' "$items_file"
    ;;
  *)
    echo "unexpected op invocation: $*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$STUB_BIN/op"

cat >"$STUB_BIN/ssh-add" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${CODEX_PROFILE_TEST_SSH_ADD_LOG:?missing ssh-add log}"
printf '%s\n' "$*" >>"$log_file"
printf 'Identity added: %s (%s)\n' "${2:-unknown}" "stub@test"
EOF
chmod +x "$STUB_BIN/ssh-add"

assert_contains() {
  local file=$1
  local expected=$2

  if ! grep -F -- "$expected" "$file" >/dev/null 2>&1; then
    echo "expected to find '$expected' in $file" >&2
    cat "$file" >&2
    exit 1
  fi
}

assert_not_contains() {
  local file=$1
  local unexpected=$2

  if grep -F -- "$unexpected" "$file" >/dev/null 2>&1; then
    echo "did not expect to find '$unexpected' in $file" >&2
    cat "$file" >&2
    exit 1
  fi
}

assert_json_equals() {
  local actual_json=$1
  local jq_expr=$2
  local expected=$3
  local actual

  actual="$(printf '%s\n' "$actual_json" | jq -r "$jq_expr")"
  if [ "$actual" != "$expected" ]; then
    echo "expected jq '$jq_expr' to equal '$expected', got '$actual'" >&2
    printf '%s\n' "$actual_json" >&2
    exit 1
  fi
}

write_auth_file() {
  local path=$1
  local api_key=$2
  local account_id=$3

  mkdir -p "$(dirname "$path")"
  cat >"$path" <<EOF
{
  "OPENAI_API_KEY": "$api_key",
  "tokens": {
    "account_id": "$account_id"
  }
}
EOF
}

new_env() {
  local home_dir=$1
  local vault_id=${2:-test-vault}

  cat >"$home_dir/.env" <<EOF
export OP_SERVICE_ACCOUNT_TOKEN=test-token
export CODEX_PROFILE_VAULT_ID=$vault_id
EOF
}

new_state_dir() {
  local name=$1
  local dir="$TMPDIR/$name"
  mkdir -p "$dir"
  printf '[]\n' >"$dir/items.json"
  : >"$dir/op.log"
  printf '%s\n' "$dir"
}

run_codex_profile() {
  local state_dir=$1
  local home_dir=$2
  shift 2
  CODEX_PROFILE_TEST_STATE_DIR="$state_dir" \
    HOME="$home_dir" \
    PATH="$STUB_BIN:$PATH" \
    OP_SERVICE_ACCOUNT_TOKEN="${CODEX_PROFILE_TEST_SERVICE_ACCOUNT_TOKEN:-test-token}" \
    CODEX_PROFILE_VAULT_ID="${CODEX_PROFILE_TEST_VAULT_ID:-test-vault}" \
    DOTFILES_ROOT="$ROOT" \
    "$ROOT/bin/codex-profile" "$@"
}

test_list_reads_1password_items() {
  local home_dir="$TMPDIR/home-list"
  local state_dir
  local output_file="$TMPDIR/list-output.txt"

  mkdir -p "$home_dir/.codex"
  new_env "$home_dir"
  write_auth_file "$home_dir/.codex/auth.json" "active-key" "acct-beta"
  state_dir="$(new_state_dir state-list)"
  cat >"$state_dir/items.json" <<'EOF'
[
  {
    "id": "item-1",
    "title": "codex/alex",
    "tags": ["codex-profile"],
    "notesPlain": "{\"OPENAI_API_KEY\":\"alex-key\",\"tokens\":{\"account_id\":\"acct-alex\"}}",
    "fields": [
      {"id": "profile_name", "label": "profile_name", "value": "alex"},
      {"id": "account_id", "label": "account_id", "value": "acct-alex"}
    ]
  },
  {
    "id": "item-2",
    "title": "codex/beta",
    "tags": ["codex-profile"],
    "notesPlain": "{\"OPENAI_API_KEY\":\"beta-key\",\"tokens\":{\"account_id\":\"acct-beta\"}}",
    "fields": [
      {"id": "profile_name", "label": "profile_name", "value": "beta"},
      {"id": "account_id", "label": "account_id", "value": "acct-beta"}
    ]
  }
]
EOF

  run_codex_profile "$state_dir" "$home_dir" list >"$output_file"

  assert_contains "$output_file" "Available profiles:"
  assert_contains "$output_file" "  alex"
  assert_contains "$output_file" "* beta (active)"
}

test_env_file_does_not_execute_shell_commands() {
  local home_dir="$TMPDIR/home-env"
  local state_dir
  local output_file="$TMPDIR/env-output.txt"
  local ssh_log="$TMPDIR/ssh-add.log"

  mkdir -p "$home_dir/.codex"
  cat >"$home_dir/.env" <<'EOF'
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
export OP_SERVICE_ACCOUNT_TOKEN=wrong-token-from-file
export CODEX_PROFILE_VAULT_ID=wrong-vault-from-file
EOF
  write_auth_file "$home_dir/.codex/auth.json" "active-key" "acct-beta"
  state_dir="$(new_state_dir state-env)"
  : >"$ssh_log"
  cat >"$state_dir/items.json" <<'EOF'
[
  {
    "id": "item-1",
    "title": "codex/alex",
    "tags": ["codex-profile"],
    "notesPlain": "{\"OPENAI_API_KEY\":\"alex-key\",\"tokens\":{\"account_id\":\"acct-beta\"}}",
    "fields": [
      {"id": "profile_name", "label": "profile_name", "value": "alex"},
      {"id": "account_id", "label": "account_id", "value": "acct-beta"}
    ]
  }
]
EOF

  CODEX_PROFILE_TEST_SSH_ADD_LOG="$ssh_log" \
    CODEX_PROFILE_TEST_SERVICE_ACCOUNT_TOKEN=test-token-from-env \
    CODEX_PROFILE_TEST_VAULT_ID=right-vault-from-env \
    run_codex_profile "$state_dir" "$home_dir" list >"$output_file"

  if [ -s "$ssh_log" ]; then
    echo "expected ~/.env commands not to execute" >&2
    cat "$ssh_log" >&2
    exit 1
  fi
  assert_not_contains "$output_file" "Identity added:"
  assert_contains "$output_file" "Available profiles:"
  assert_contains "$state_dir/op.log" "--vault right-vault-from-env"
  assert_not_contains "$state_dir/op.log" "--vault wrong-vault-from-file"
}

test_first_run_migration_imports_local_profiles() {
  local home_dir="$TMPDIR/home-migrate"
  local state_dir
  local output_file="$TMPDIR/migrate-output.txt"
  local items_json

  mkdir -p "$home_dir/.codex/profiles/alex" "$home_dir/.codex/profiles/beta"
  new_env "$home_dir"
  write_auth_file "$home_dir/.codex/profiles/alex/auth.json" "alex-key" "acct-alex"
  write_auth_file "$home_dir/.codex/profiles/beta/auth.json" "beta-old-key" "acct-beta"
  write_auth_file "$home_dir/.codex/auth.json" "beta-current-key" "acct-beta"
  state_dir="$(new_state_dir state-migrate)"

  printf 'y\n' | run_codex_profile "$state_dir" "$home_dir" list >"$output_file"

  items_json="$(cat "$state_dir/items.json")"
  assert_json_equals "$items_json" 'length' "2"
  assert_json_equals "$items_json" '[.[].title] | sort | join(",")' "codex/alex,codex/beta"
  assert_json_equals "$items_json" 'map(select(.title == "codex/beta"))[0].notesPlain | fromjson | .OPENAI_API_KEY' "beta-current-key"
  assert_contains "$output_file" "Local profiles to import:"
  assert_contains "$output_file" "* beta (active)"
}

test_first_run_migration_prompts_for_unmatched_active_auth_name() {
  local home_dir="$TMPDIR/home-migrate-unmatched"
  local state_dir
  local output_file="$TMPDIR/migrate-unmatched-output.txt"
  local items_json

  mkdir -p "$home_dir/.codex/profiles/alex"
  new_env "$home_dir"
  write_auth_file "$home_dir/.codex/profiles/alex/auth.json" "alex-key" "acct-alex"
  write_auth_file "$home_dir/.codex/auth.json" "gamma-key" "acct-gamma"
  state_dir="$(new_state_dir state-migrate-unmatched)"

  printf 'gamma\ny\n' | run_codex_profile "$state_dir" "$home_dir" list >"$output_file"

  items_json="$(cat "$state_dir/items.json")"
  assert_json_equals "$items_json" '[.[].title] | sort | join(",")' "codex/alex,codex/gamma"
  assert_json_equals "$items_json" 'map(select(.title == "codex/gamma"))[0].notesPlain | fromjson | .OPENAI_API_KEY' "gamma-key"
  assert_contains "$output_file" "Current auth will also be imported as 'gamma'."
}

test_save_updates_existing_remote_profile() {
  local home_dir="$TMPDIR/home-save"
  local state_dir
  local items_json

  mkdir -p "$home_dir/.codex"
  new_env "$home_dir"
  write_auth_file "$home_dir/.codex/auth.json" "alex-new-key" "acct-alex"
  state_dir="$(new_state_dir state-save)"
  cat >"$state_dir/items.json" <<'EOF'
[
  {
    "id": "item-1",
    "title": "codex/alex",
    "tags": ["codex-profile"],
    "notesPlain": "{\"OPENAI_API_KEY\":\"alex-old-key\",\"tokens\":{\"account_id\":\"acct-alex\"}}",
    "fields": [
      {"id": "profile_name", "label": "profile_name", "value": "alex"},
      {"id": "account_id", "label": "account_id", "value": "acct-alex"}
    ]
  }
]
EOF

  run_codex_profile "$state_dir" "$home_dir" save alex >/dev/null

  items_json="$(cat "$state_dir/items.json")"
  assert_json_equals "$items_json" 'map(select(.title == "codex/alex"))[0].notesPlain | fromjson | .OPENAI_API_KEY' "alex-new-key"
  assert_json_equals "$items_json" 'map(select(.title == "codex/alex"))[0].fields[] | select(.id == "account_id") | .value' "acct-alex"
}

test_switch_autosaves_current_auth_and_applies_target() {
  local home_dir="$TMPDIR/home-switch"
  local state_dir
  local items_json

  mkdir -p "$home_dir/.codex"
  new_env "$home_dir" "override-vault"
  write_auth_file "$home_dir/.codex/auth.json" "alex-current-key" "acct-alex"
  state_dir="$(new_state_dir state-switch)"
  cat >"$state_dir/items.json" <<'EOF'
[
  {
    "id": "item-1",
    "title": "codex/alex",
    "tags": ["codex-profile"],
    "notesPlain": "{\"OPENAI_API_KEY\":\"alex-old-key\",\"tokens\":{\"account_id\":\"acct-alex\"}}",
    "fields": [
      {"id": "profile_name", "label": "profile_name", "value": "alex"},
      {"id": "account_id", "label": "account_id", "value": "acct-alex"}
    ]
  },
  {
    "id": "item-2",
    "title": "codex/beta",
    "tags": ["codex-profile"],
    "notesPlain": "{\"OPENAI_API_KEY\":\"beta-key\",\"tokens\":{\"account_id\":\"acct-beta\"}}",
    "fields": [
      {"id": "profile_name", "label": "profile_name", "value": "beta"},
      {"id": "account_id", "label": "account_id", "value": "acct-beta"}
    ]
  }
]
EOF

  CODEX_PROFILE_TEST_VAULT_ID=override-vault run_codex_profile "$state_dir" "$home_dir" switch beta >/dev/null

  items_json="$(cat "$state_dir/items.json")"
  assert_json_equals "$items_json" 'map(select(.title == "codex/alex"))[0].notesPlain | fromjson | .OPENAI_API_KEY' "alex-current-key"
  assert_json_equals "$(cat "$home_dir/.codex/auth.json")" '.OPENAI_API_KEY' "beta-key"
  assert_contains "$state_dir/op.log" "--vault override-vault"
}

test_switch_prompts_for_unmatched_current_auth_name() {
  local home_dir="$TMPDIR/home-switch-unmatched"
  local state_dir
  local items_json

  mkdir -p "$home_dir/.codex"
  new_env "$home_dir"
  write_auth_file "$home_dir/.codex/auth.json" "gamma-key" "acct-gamma"
  state_dir="$(new_state_dir state-switch-unmatched)"
  cat >"$state_dir/items.json" <<'EOF'
[
  {
    "id": "item-1",
    "title": "codex/beta",
    "tags": ["codex-profile"],
    "notesPlain": "{\"OPENAI_API_KEY\":\"beta-key\",\"tokens\":{\"account_id\":\"acct-beta\"}}",
    "fields": [
      {"id": "profile_name", "label": "profile_name", "value": "beta"},
      {"id": "account_id", "label": "account_id", "value": "acct-beta"}
    ]
  }
]
EOF

  printf 'gamma\ny\n' | run_codex_profile "$state_dir" "$home_dir" switch beta >/dev/null

  items_json="$(cat "$state_dir/items.json")"
  assert_json_equals "$items_json" '[.[].title] | sort | join(",")' "codex/beta,codex/gamma"
  assert_json_equals "$items_json" 'map(select(.title == "codex/gamma"))[0].notesPlain | fromjson | .OPENAI_API_KEY' "gamma-key"
}

test_init_command_is_removed() {
  local home_dir="$TMPDIR/home-no-init"
  local state_dir
  local output_file="$TMPDIR/no-init-output.txt"
  local status=0

  mkdir -p "$home_dir/.codex"
  new_env "$home_dir"
  state_dir="$(new_state_dir state-no-init)"

  set +e
  run_codex_profile "$state_dir" "$home_dir" init newprofile >"$output_file" 2>&1
  status=$?
  set -e

  if [ "$status" -eq 0 ]; then
    echo "expected init command to be unavailable" >&2
    cat "$output_file" >&2
    exit 1
  fi

  assert_contains "$output_file" "Codex Profile Switcher"
  assert_not_contains "$output_file" "init <new_profile_name>"
}

main() {
  test_list_reads_1password_items
  test_env_file_does_not_execute_shell_commands
  test_first_run_migration_imports_local_profiles
  test_first_run_migration_prompts_for_unmatched_active_auth_name
  test_save_updates_existing_remote_profile
  test_switch_autosaves_current_auth_and_applies_target
  test_switch_prompts_for_unmatched_current_auth_name
  test_init_command_is_removed
  echo "PASS"
}

main "$@"
