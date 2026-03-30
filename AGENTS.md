# Repository Guidance

This repository is public.

Treat that as a hard constraint when making changes:

- Do not commit secrets, tokens, private keys, certificates, or credentials.
- Do not commit local generated state such as editor history, caches, or machine-specific exports.
- Be careful with host-specific values like SSIDs, private IPs, device serials, usernames, and absolute local paths.
- Prefer placeholders, `*.example` files, and ignored local overlays for machine-specific configuration.

When reorganizing or adding files, keep the repo zones clear:

- `bin/` for user-facing commands
- `dotfiles/` for shell/editor/git config and setup scripts
- `tooling/` for app-specific config that is safe to publish
- `infra/` for infrastructure and self-hosting automation
- `lib/` for reusable helpers
- `archive/` for retired material
