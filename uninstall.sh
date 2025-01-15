#!/bin/bash

# Variables
USER_HOME=$(eval echo ~${SUDO_USER})
PACKAGE_URL="https://github.com/muesli/deckmaster/releases/download/v0.9.0/deckmaster_0.9.0_linux_amd64.deb" # Remplacez par le lien du package
UDEV_RULES_FILE="/etc/udev/rules.d/99-streamdeck.rules"
SYSTEMD_PATH_FILE="$USER_HOME/.config/systemd/user/streamdeck.path"
SYSTEMD_SERVICE_FILE="$USER_HOME/.config/systemd/user/streamdeck.service"

if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root pour certaines étapes (e.g., création de fichiers dans /etc/udev)."
  exit 1
fi

echo "Désinstallation de deckmaster..."

apt remove -y deckmaster

echo "Suppression des fichiers..."

rm -f "$UDEV_RULES_FILE"
rm -f "$SYSTEMD_PATH_FILE"
rm -f "$SYSTEMD_SERVICE_FILE"
rm -rf "$USER_HOME/.config/proxmox_controller"

echo "Rechargement des règles udev..."

udevadm control --reload-rules

echo "Désactivation et arrêt du chemin systemd..."

USER_ID=$(id -u "${SUDO_USER}")
loginctl enable-linger "$SUDO_USER"
runuser -u "${SUDO_USER}" -- bash -c "XDG_RUNTIME_DIR=/run/user/$USER_ID systemctl --user daemon-reload"

pkill -f deckmaster
