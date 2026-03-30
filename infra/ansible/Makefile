.PHONY: install ping bootstrap deploy dokploy portainer homeassistant homepage pihole lint check

# Install Python dependencies
install:
	uv sync

# Test connectivity to homelab
ping:
	uv run ansible -m ping homelab

# First-time setup of a fresh machine
bootstrap:
	uv run ansible-playbook playbooks/bootstrap.yml --ask-become-pass

# Full deploy (common + docker services)
deploy:
	uv run ansible-playbook site.yml --ask-become-pass

# Install Dokploy on homelab
dokploy:
	uv run ansible-playbook playbooks/dokploy.yml --ask-become-pass

# Install Portainer on homelab
portainer:
	uv run ansible-playbook playbooks/portainer.yml --ask-become-pass

# Install Home Assistant on homelab
homeassistant:
	uv run ansible-playbook playbooks/homeassistant.yml --ask-become-pass

# Install Homepage on homelab
homepage:
	uv run ansible-playbook playbooks/homepage.yml --ask-become-pass

# Install Pi-hole on homelab
pihole:
	uv run ansible-playbook playbooks/pihole.yml --ask-become-pass

# Syntax check all playbooks
check:
	uv run ansible-playbook site.yml --check
	uv run ansible-playbook playbooks/bootstrap.yml --check

# Lint playbooks (requires ansible-lint)
lint:
	uv run ansible-lint site.yml playbooks/bootstrap.yml
