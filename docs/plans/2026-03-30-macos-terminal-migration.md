# macOS Terminal Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:verifying-plan before execution, then superpowers:executing-plans or superpowers:subagent-driven-development to implement task-by-task.

**Goal:** Migrate this public dotfiles repo to a modern macOS terminal/tooling setup built around Ghostty, Prezto, mise, and grouped Homebrew installs while preserving the repo's public-safe structure and symlink workflow.

**Architecture:** Keep one macOS bootstrap entrypoint in `dotfiles/scripts/setup/darwin.sh`, but reorganize its contents into explicit install groups with deterministic helper functions. Treat Ghostty as a managed config under `tooling/ghostty/`, keep `bin/` as thin entrypoints, and rewrite `dotfiles/shell/zshrc` around Prezto-native startup plus tool init hooks for installed CLI utilities. Preserve the repo's symlink-based setup model rather than introducing a second dotfiles manager.

**Tech Stack:** macOS, Homebrew, Zsh, Prezto, Ghostty, mise with `.tool-versions`, tmux, zellij, shell scripts

---

### Task 1: Capture Current Ghostty Config In-Repo

**Files:**
- Create: `tooling/ghostty/config`
- Modify: `dotfiles/scripts/makesymlinks.sh`
- Modify: `README.md`

**Step 1: Copy the active Ghostty config into the repo**

Use `/Users/ozeron/.config/ghostty/config` as the source and create a managed copy at `tooling/ghostty/config`.

**Step 2: Add symlink support for Ghostty config**

Update `dotfiles/scripts/makesymlinks.sh` so it:
- creates `~/.config/ghostty`
- symlinks `tooling/ghostty/config` to `~/.config/ghostty/config`

**Step 3: Document Ghostty as a managed tooling config**

Update `README.md` to state that Ghostty config is managed from the repo and linked into `~/.config/ghostty/config`.

**Step 4: Verify**

Run:
```bash
bash -n dotfiles/scripts/makesymlinks.sh
```

Expected: exit code `0`

**Step 5: Commit**

```bash
git add tooling/ghostty/config dotfiles/scripts/makesymlinks.sh README.md
git commit -m "tooling: manage ghostty config from repo"
```

### Task 2: Rewrite macOS Bootstrap Around Grouped Installs

**Files:**
- Modify: `dotfiles/scripts/setup/darwin.sh`
- Modify: `README.md`

**Step 1: Replace the current ad hoc install list with grouped sections**

Rewrite `dotfiles/scripts/setup/darwin.sh` so one file installs tools in clearly commented groups:
- bootstrap/homebrew
- terminal apps
- shell/tooling
- search/navigation tools
- git tools
- runtime/toolchain
- optional power tools

**Step 2: Install the selected packages**

The grouped install set should include:
- Casks: `ghostty`, `docker`, `telegram`, `raycast`, `font-jetbrains-mono-nerd-font`
- Formulae: `zsh`, `git`, `vim`, `ctags`, `ripgrep`, `fd`, `zoxide`, `fzf`, `bat`, `eza`, `atuin`, `tldr`, `git-delta`, `btop`, `jq`, `lazygit`, `yazi`, `zellij`, `dust`, `sd`, `glow`, `hyperfine`, `tmux`, `mise`, `direnv`, `gnupg`, `readline`, `openssl`

**Step 3: Remove obsolete setup behavior**

Delete or replace:
- `asdf` install/setup
- `powerlevel10k` install
- `oh-my-zsh` install

**Step 4: Add any one-time installer hooks required by adopted tools**

Examples:
- `fzf` shell integration install, if needed
- `mise` activation handled in shell config, not here
- Prezto installation handled separately from package groups

**Step 5: Document grouped bootstrap behavior**

Update `README.md` with a short “new Mac” section that points to `./dotfiles/scripts/config.sh` and describes the grouped installer approach.

**Step 6: Verify**

Run:
```bash
bash -n dotfiles/scripts/setup/darwin.sh
```

Expected: exit code `0`

**Step 7: Commit**

```bash
git add dotfiles/scripts/setup/darwin.sh README.md
git commit -m "setup: group macOS bootstrap installs"
```

### Task 3: Migrate Zsh Startup From Oh My Zsh To Prezto

**Files:**
- Modify: `dotfiles/shell/zshrc`
- Optionally Remove: `dotfiles/shell/p10k.zsh`
- Modify: `dotfiles/scripts/setup/darwin.sh`
- Modify: `README.md`

**Step 1: Replace Oh My Zsh and powerlevel10k startup logic**

Rewrite `dotfiles/shell/zshrc` to remove:
- `oh-my-zsh` initialization
- `powerlevel10k` instant prompt setup
- `asdf` initialization

**Step 2: Add Prezto-native startup**

Use a standard Prezto bootstrap flow:
- set `ZDOTDIR` assumptions only if needed
- source `~/.zprezto/init.zsh` when present
- avoid repo-specific hardcoded plugin framework paths

**Step 3: Preserve existing useful aliases and functions**

Carry forward the useful local aliases/functions that still make sense, but remove framework-specific assumptions that no longer apply.

**Step 4: Add runtime/tool hooks**

Wire these into `zshrc` if installed:
- `mise activate zsh`
- `zoxide init zsh`
- `atuin init zsh`
- `fzf` shell usage if needed
- keep `direnv hook zsh`

**Step 5: Add Prezto install/setup to Darwin bootstrap**

Ensure `dotfiles/scripts/setup/darwin.sh` clones Prezto into `~/.zprezto` if missing without committing local Prezto state.

**Step 5a: Keep runtime version files on `.tool-versions`**

Do not introduce `mise.toml` in this migration. Keep [`dotfiles/shell/tool-versions`](/Users/ozeron/code/dotfiles/dotfiles/shell/tool-versions) as the shared version file and rely on `mise` to consume it.

**Step 6: Decide fate of `p10k.zsh`**

If no longer needed, move it to `archive/` or delete it from active dotfiles references. Do not leave dead references in `zshrc` or the symlink script.

**Step 7: Verify**

Run:
```bash
zsh -n dotfiles/shell/zshrc
bash -n dotfiles/scripts/setup/darwin.sh
```

Expected: both exit code `0`

**Step 8: Commit**

```bash
git add dotfiles/shell/zshrc dotfiles/scripts/setup/darwin.sh README.md
git commit -m "shell: switch macOS zsh setup to prezto and mise"
```

### Task 4: Improve Symlink And Command Linking Behavior

**Files:**
- Modify: `dotfiles/scripts/makesymlinks.sh`
- Review: `bin/*`
- Modify: `README.md`

**Step 1: Keep home dotfile symlinks aligned with the new repo layout**

Ensure `dotfiles/scripts/makesymlinks.sh` symlinks:
- `~/.zshrc`
- `~/.gitconfig`
- `~/.vimrc`
- `~/.vim`
- `~/.tool-versions` if still intentionally used
- `~/.claude/settings.json`
- `~/.config/ghostty/config`

**Step 2: Remove legacy or unsafe symlink targets**

Do not symlink:
- `viminfo`
- deleted framework files
- old repo paths

**Step 3: Define command-linking behavior**

Keep the existing `~/bin -> <repo>/bin` symlink if that is the intended model. Verify `bin/` remains only user-facing commands and `lib/` remains non-PATH helper code.

**Step 4: Verify wrapper scripts against moved library paths**

Check that repo wrappers such as `bin/codex-profile` still point to the correct file under `lib/`.

**Step 5: Verify**

Run:
```bash
bash -n dotfiles/scripts/makesymlinks.sh
bash -n bin/codex-profile lib/codex-profile.sh
```

Expected: exit code `0`

**Step 6: Commit**

```bash
git add dotfiles/scripts/makesymlinks.sh bin/codex-profile lib/codex-profile.sh README.md
git commit -m "dotfiles: tighten symlink and command-link setup"
```

### Task 5: Refresh Documentation For Public Safe Bootstrap

**Files:**
- Modify: `README.md`
- Review: `AGENTS.md`

**Step 1: Add a concise “new Mac” section**

Document:
- bootstrap command
- managed Ghostty config
- Prezto + mise choice
- grouped install behavior

**Step 2: Keep the public-safe rules visible**

Make sure `README.md` and `AGENTS.md` stay aligned on:
- no secrets
- no local generated state
- placeholders for local-only config

**Step 3: Verify**

Run:
```bash
rg -n "oh-my-zsh|powerlevel10k|asdf" dotfiles README.md
```

Expected: only intentional references remain, or none if fully migrated

**Step 4: Commit**

```bash
git add README.md AGENTS.md
git commit -m "docs: document terminal migration and public-safe setup"
```
