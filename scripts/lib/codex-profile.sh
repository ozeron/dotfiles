#!/bin/bash

CODEX_DIR="$HOME/.codex"
PROFILES_DIR="$CODEX_DIR/profiles"
JQ_WARNED=0

# Flows this script aims to handle:
# 1) Active detection: computed from auth.json -> tokens.account_id, never a marker file.
# 2) Token refresh drift: save overwrites a profile with the current refreshed tokens.
# 3) Any switch operation always autosaves current state first.
# 4) Safety fallback: if current state exists but cannot be mapped to a profile, save a timestamped snapshot.

# Extract a stable account identifier from an auth.json file.
function get_account_id() {
    local file=$1
    [ -f "$file" ] || return 1
    if ! command -v jq >/dev/null 2>&1; then
        if [ "$JQ_WARNED" -eq 0 ]; then
            echo "Warning: jq is not installed; account matching is disabled." >&2
            JQ_WARNED=1
        fi
        return 1
    fi
    jq -r '.tokens.account_id // empty' "$file" 2>/dev/null
}

# Allow only simple profile names to keep reads/writes inside PROFILES_DIR.
function validate_profile_name() {
    local name=$1
    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]]
}

# Find a saved profile that matches the provided account_id.
function find_profile_by_account_id() {
    local account_id=$1
    [ -n "$account_id" ] || return 0
    while IFS= read -r -d '' dir; do
        local p
        p=$(basename "$dir")
        local profile_account_id=""
        profile_account_id=$(get_account_id "$PROFILES_DIR/$p/auth.json")
        if [ -n "$profile_account_id" ] && [ "$profile_account_id" = "$account_id" ]; then
            echo "$p"
            return 0
        fi
    done < <(find "$PROFILES_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
}

# List all saved profiles and indicate the currently active one
function list_profiles() {
    if [ ! -d "$PROFILES_DIR" ] || [ -z "$(ls -A "$PROFILES_DIR" 2>/dev/null | grep -v "^\.")" ]; then
        echo "No profiles found."
        return 0
    fi

    local active=""
    local current_account_id=""
    current_account_id=$(get_account_id "$CODEX_DIR/auth.json")

    # Prefer detection based on account_id, since tokens can refresh.
    if [ -n "$current_account_id" ]; then
        while IFS= read -r -d '' dir; do
            local p
            p=$(basename "$dir")
            local profile_account_id=""
            profile_account_id=$(get_account_id "$PROFILES_DIR/$p/auth.json")
            if [ -n "$profile_account_id" ] && [ "$profile_account_id" = "$current_account_id" ]; then
                active="$p"
                break
            fi
        done < <(find "$PROFILES_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    fi

    echo "Available profiles:"
    while IFS= read -r -d '' dir; do
        local p
        p=$(basename "$dir")
        if [ "$p" == "$active" ]; then
            echo "* $p (active)"
        else
            echo "  $p"
        fi
    done < <(find "$PROFILES_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
}

# Save current auth.json and config.toml to a named profile
function save_profile() {
    local name=$1
    if [ -z "$name" ]; then
        echo "Usage: codex-profile save <name>"
        return 1
    fi
    if ! validate_profile_name "$name"; then
        echo "Error: Invalid profile name '$name'. Allowed: letters, numbers, ., _, -"
        return 1
    fi
    mkdir -p "$PROFILES_DIR/$name" || {
        echo "Error: Failed to create profile directory '$PROFILES_DIR/$name'."
        return 1
    }

    local copied=0
    if [ -f "$CODEX_DIR/auth.json" ]; then
        cp "$CODEX_DIR/auth.json" "$PROFILES_DIR/$name/" || {
            echo "Error: Failed to save auth.json to profile '$name'."
            return 1
        }
        copied=1
    fi
    if [ -f "$CODEX_DIR/config.toml" ]; then
        cp "$CODEX_DIR/config.toml" "$PROFILES_DIR/$name/" || {
            echo "Error: Failed to save config.toml to profile '$name'."
            return 1
        }
        copied=1
    fi
    if [ "$copied" -eq 0 ]; then
        echo "Error: Nothing to save (missing $CODEX_DIR/auth.json and $CODEX_DIR/config.toml)."
        return 1
    fi
    echo "Current state saved to profile '$name'."
}

# Switch to a different profile by copying its files to the main Codex directory
function switch_profile() {
    local name=$1
    if [ -z "$name" ]; then
        echo "Usage: codex-profile switch <name>"
        return 1
    fi
    if ! validate_profile_name "$name"; then
        echo "Error: Invalid profile name '$name'. Allowed: letters, numbers, ., _, -"
        return 1
    fi
    if [ ! -d "$PROFILES_DIR/$name" ]; then
        echo "Error: Profile '$name' not found."
        return 1
    fi
    local target_auth="$PROFILES_DIR/$name/auth.json"
    local target_config="$PROFILES_DIR/$name/config.toml"
    if [ ! -f "$target_auth" ] && [ ! -f "$target_config" ]; then
        echo "Error: Profile '$name' has no auth.json or config.toml to switch to."
        return 1
    fi

    local current_account_id=""
    current_account_id=$(get_account_id "$CODEX_DIR/auth.json")
    local current_auth_exists=0
    if [ -f "$CODEX_DIR/auth.json" ] || [ -f "$CODEX_DIR/config.toml" ]; then
        current_auth_exists=1
    fi

    local current_profile=""
    if [ -n "$current_account_id" ]; then
        current_profile=$(find_profile_by_account_id "$current_account_id")
    fi

    # Always autosave current state before switching.
    if [ "$current_auth_exists" -eq 1 ]; then
        if [ -n "$current_profile" ]; then
            echo "Autosaving current state to profile '$current_profile'..."
            save_profile "$current_profile" || return 1
        else
            local ts
            ts=$(date +%Y%m%d_%H%M%S)
            echo "Autosaving current state to snapshot 'auto_$ts'..."
            save_profile "auto_$ts" || return 1
        fi
    fi
    
    local switch_tmp_dir=""
    switch_tmp_dir=$(mktemp -d "$CODEX_DIR/.switch_tmp.XXXXXX") || {
        echo "Error: Failed to create temporary directory for switch."
        return 1
    }
    if [ -f "$target_auth" ]; then
        cp "$target_auth" "$switch_tmp_dir/auth.json" || {
            rm -rf "$switch_tmp_dir"
            echo "Error: Failed to stage auth.json from profile '$name'."
            return 1
        }
    fi
    if [ -f "$target_config" ]; then
        cp "$target_config" "$switch_tmp_dir/config.toml" || {
            rm -rf "$switch_tmp_dir"
            echo "Error: Failed to stage config.toml from profile '$name'."
            return 1
        }
    fi

    if [ -f "$switch_tmp_dir/auth.json" ]; then
        mv "$switch_tmp_dir/auth.json" "$CODEX_DIR/auth.json" || {
            rm -rf "$switch_tmp_dir"
            echo "Error: Failed to apply auth.json for profile '$name'."
            return 1
        }
    else
        rm -f "$CODEX_DIR/auth.json"
    fi
    if [ -f "$switch_tmp_dir/config.toml" ]; then
        mv "$switch_tmp_dir/config.toml" "$CODEX_DIR/config.toml" || {
            rm -rf "$switch_tmp_dir"
            echo "Error: Failed to apply config.toml for profile '$name'."
            return 1
        }
    else
        rm -f "$CODEX_DIR/config.toml"
    fi
    rm -rf "$switch_tmp_dir"
    
    echo "Switched to profile '$name'."
}

# Remove the current auth and config files (equivalent to logging out)
function clear_current() {
    rm -f "$CODEX_DIR/auth.json" "$CODEX_DIR/config.toml"
    echo "Current auth and config cleared (Logged out)."
}

# Initialize a new profile by backing up the current state and starting fresh
function init_profile() {
    local name=$1
    if [ -z "$name" ]; then
        echo "Usage: codex-profile init <new_profile_name>"
        return 1
    fi
    if ! validate_profile_name "$name"; then
        echo "Error: Invalid profile name '$name'. Allowed: letters, numbers, ., _, -"
        return 1
    fi

    # 1. Save current state to a timestamped backup when files exist.
    local current_state_exists=0
    if [ -f "$CODEX_DIR/auth.json" ] || [ -f "$CODEX_DIR/config.toml" ]; then
        current_state_exists=1
    fi
    if [ "$current_state_exists" -eq 1 ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup="backup_$timestamp"
        echo "Backing up current state to '$backup'..."
        save_profile "$backup" || {
            echo "Error: Backup failed. Init canceled to avoid data loss."
            return 1
        }
    else
        echo "No current state found. Skipping backup."
    fi

    # 2. Clear current files
    clear_current

    # 3. Create the new empty profile directory
    mkdir -p "$PROFILES_DIR/$name"
    
    echo "New profile '$name' initialized. Ready for new login."
}

function show_help() {
    echo "Codex Profile Switcher"
    echo ""
    echo "Manage multiple Codex authentication profiles and configurations."
    echo ""
    echo "Usage: codex-profile <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  list                      List all available profiles and show the active one."
    echo "  save <name>               Save the current auth and config to a profile named <name>."
    echo "  switch <name>             Switch to the profile named <name>."
    echo "  init <new_profile_name>   Initialize a new profile. Backs up current state first."
    echo "  clear                     Clear the current active auth and config (logout)."
    echo "  help, -h, --help          Show this help message."
    echo ""
}

case "$1" in
    list)
        list_profiles
        ;;
    save)
        save_profile "$2"
        ;;
    switch)
        switch_profile "$2"
        ;;
    clear)
        clear_current
        ;;
    init)
        init_profile "$2"
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac
