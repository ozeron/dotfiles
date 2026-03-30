# dotfiles



# some changes
Copied Chromedriver to

open /Users/ozeron/.asdf/installs/ruby/2.6.5/bin/
backup in /Users/ozeron/.asdf/installs/ruby/2.6.5/

## Homelab boot + SSH before login

To make SSH available immediately after boot on Arch, ensure the bootstrap playbook has run:

```bash
cd ansible
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
