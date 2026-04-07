# dotfiles

Public personal setup repo with a few clear zones:

- `bin/`: user-facing commands kept on `PATH`
- `dotfiles/`: shell, git, vim config plus dotfile setup scripts
- `tooling/`: app-specific config that is safe to publish
- `infra/`: homelab Ansible and self-hosting files
- `lib/`: reusable helper scripts used by `bin/`
- `archive/`: retired or backup material

## Public Repo Rules

This repository is public. Do not commit:

- credentials, tokens, private keys, certificates, or secrets
- real home IPs, SSIDs, device serials, or machine-specific hostnames unless they are clearly safe
- local-only generated state such as editor history files

Prefer placeholders, `*.example` files, and ignored local overlays.

Before using the homelab automation on a real machine, update:

- [`infra/ansible/inventory/hosts.yml`](/Users/ozeron/code/dotfiles/infra/ansible/inventory/hosts.yml) with your host/user values
- [`infra/ansible/inventory/group_vars/homelab.yml`](/Users/ozeron/code/dotfiles/infra/ansible/inventory/group_vars/homelab.yml) with your local device paths and DNS values
- `infra/selfhost/certs/cert.pem` and `infra/selfhost/certs/key.pem` locally if you use the Traefik TLS setup

## New Mac

For a new macOS machine:

```bash
./dotfiles/scripts/config.sh
```

The setup installs grouped dependencies from one bootstrap file:

- terminal apps: Ghostty, Docker, Raycast, Telegram, fonts
- shell and editors: Zsh, Vim, Direnv, Ctags
- search and navigation: ripgrep, fd, zoxide, fzf, bat, eza, atuin, tldr, jq
- git and workflow: git-delta, lazygit, tmux, zellij
- runtime and toolchain: mise, gnupg, readline, openssl
- power tools: btop, yazi, dust, sd, glow, hyperfine

Shell startup is now built around Prezto with `mise` consuming `.tool-versions`.
Ghostty config is managed in [`tooling/ghostty/config`](tooling/ghostty/config) and symlinked to `~/.config/ghostty/config`.

## Dotfiles Setup

The bootstrap helpers now live under `dotfiles/scripts/`.

```bash
./dotfiles/scripts/config.sh
```

## Homelab Boot + SSH Before Login

To make SSH available immediately after boot on Arch, ensure the bootstrap playbook has run:

```bash
cd infra/ansible
make bootstrap
```

If the host is on Wi-Fi and SSH still only works after desktop login, convert the Wi-Fi profile from user-scoped to system-scoped:

```bash
sudo nmcli connection show
sudo nmcli connection modify "<WIFI_CONNECTION_NAME>" connection.permissions ""
sudo nmcli connection modify "<WIFI_CONNECTION_NAME>" wifi-sec.psk-flags 0
sudo nmcli connection up "<WIFI_CONNECTION_NAME>"
```

This prevents the network secret from being locked behind the user session keyring.
