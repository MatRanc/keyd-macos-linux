#!/usr/bin/env bash
# Installs keyd (if needed) and this repo's default.conf, then enables the
# service and repoints GNOME's overlay-key so tap-alone-opens-Activities
# keeps working on the new Cmd (Alt) key. Designed for Fedora; on other
# distros, install keyd yourself (see README) then just run the last part.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v keyd >/dev/null 2>&1; then
  if command -v dnf >/dev/null 2>&1; then
    echo "Installing keyd via the alternateved/keyd COPR repo..."
    sudo dnf copr enable -y alternateved/keyd
    sudo dnf install -y keyd
  else
    echo "keyd not found and this isn't a dnf-based distro." >&2
    echo "Install keyd yourself (see README.md), then re-run this script." >&2
    exit 1
  fi
fi

echo "Installing config to /etc/keyd/default.conf..."
sudo mkdir -p /etc/keyd
sudo cp "$REPO_DIR/default.conf" /etc/keyd/default.conf

echo "Validating config..."
sudo keyd check /etc/keyd/default.conf || true  # non-fatal style warnings are expected

echo "Enabling and starting keyd..."
sudo systemctl enable --now keyd
sudo systemctl restart keyd

if command -v gsettings >/dev/null 2>&1; then
  echo "Repointing GNOME's overlay-key to Alt_L (tap Cmd alone -> Activities)..."
  gsettings set org.gnome.mutter overlay-key 'Alt_L'
else
  echo "gsettings not found; skipping overlay-key rebind (not on GNOME?)."
fi

echo "Done. Try Alt+C / Alt+V to copy/paste, and tap Alt alone for Activities."
