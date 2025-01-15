#!/bin/bash

# Variables
USER_HOME=$(eval printf ~${SUDO_USER})
PACKAGE_URL="https://github.com/muesli/deckmaster/releases/download/v0.9.0/deckmaster_0.9.0_linux_amd64.deb" # Remplacez par le lien du package
PACKAGE_NAME=$(basename "$PACKAGE_URL") # Nom du package extrait du lien
UDEV_RULES_FILE="/etc/udev/rules.d/99-streamdeck.rules"
SYSTEMD_PATH_FILE="$USER_HOME/.config/systemd/user/streamdeck.path"
SYSTEMD_SERVICE_FILE="$USER_HOME/.config/systemd/user/streamdeck.service"
PROXMOX_CONTROLLER_PATH="$USER_HOME/.config/proxmox_controller"

STEP=1;
MAX_STEP=12;
# Vérifier si le script est exécuté avec les droits root pour certaines étapes
if [ "$EUID" -ne 0 ]; then
  printf "Ce script doit être exécuté en tant que root pour certaines étapes (e.g., création de fichiers dans /etc/udev)."
  exit 1
fi

# Etape 1: Création du dossier de proxmox_controller
printf "$STEP/$MAX_STEP Création du fichier start.sh...\n"
mkdir -p "$PROXMOX_CONTROLLER_PATH"
chown $SUDO_USER "$PROXMOX_CONTROLLER_PATH"

printf "$STEP/$MAX_STEP Reussie !\n\n"
STEP=$((STEP+1));

# Etape 2: Création du fichier vm_list.sh ...
printf "$STEP/$MAX_STEP Création du fichier start.sh...\n"
cp $PWD/sub_scripts/vm_list.sh $PROXMOX_CONTROLLER_PATH/vm_list.sh 
chmod +x "$PROXMOX_CONTROLLER_PATH/vm_list.sh"


printf "$STEP/$MAX_STEP Reussie !\n\n"
STEP=$((STEP+1));

# Etape 3: Création du fichier start.sh
printf "$STEP/$MAX_STEP : Création du fichier start.sh...\n"
cp $PWD/sub_scripts/start.sh $PROXMOX_CONTROLLER_PATH/start.sh 
chmod +x "$PROXMOX_CONTROLLER_PATH/start.sh"

printf "$STEP/$MAX_STEP Reussie !\n\n"
STEP=$((STEP+1));
# Etape 4: Copie des icônes et templates
printf "$STEP/$MAX_STEP : Copie des icônes...\n"
cp -r -R $PWD/icons "$PROXMOX_CONTROLLER_PATH/assets"
cp -r -R $PWD/templates "$PROXMOX_CONTROLLER_PATH/templates"


printf "$STEP/$MAX_STEP Reussie !\n\n"
STEP=$((STEP+1));
# Etape 5: Création du fichier create.sh
printf "$STEP/$MAX_STEP : Création du fichier create.sh...\n"
cp $PWD/sub_scripts/create.sh $PROXMOX_CONTROLLER_PATH/create.sh
chmod +x "$PROXMOX_CONTROLLER_PATH/create.sh"

printf "$STEP/$MAX_STEP Reussie !\n\n"
STEP=$((STEP+1));
# Étape 6: Télécharger et installer le package
printf "$STEP/$MAX_STEP : Téléchargement et installation du package...\n"
wget -O "/tmp/$PACKAGE_NAME" "$PACKAGE_URL"
apt install -y "/tmp/$PACKAGE_NAME"
rm "/tmp/$PACKAGE_NAME"

printf "$STEP/$MAX_STEP Reussie !\n\n"
STEP=$((STEP+1));
# Étape 7: Créer un fichier .rules dans /etc/udev/rules.d/
printf "$STEP/$MAX_STEP : Création du fichier udev rules...\n"
cp $PWD/files/99-streamdeck.rules $UDEV_RULES_FILE

printf "$STEP/$MAX_STEP Reussie !\n\n"
STEP=$((STEP+1));
# Étape 8: Changer le propriétaire de /dev/uinput afin d'éviter les messages d'errreurs
printf "$STEP/$MAX_STEP : Changement du propriétaire de /dev/uinput...\n"
chown root:plugdev /dev/uinput

printf "$STEP/$MAX_STEP Reussie !\n\n"
STEP=$((STEP+1));
# Étape 9: Créer un fichier .path dans .config/systemd/user/
printf "$STEP/$MAX_STEP : Création du fichier systemd path...\n"
cp $PWD/files/streamdeck.path $SYSTEMD_PATH_FILE

printf "$STEP/$MAX_STEP Reussie !\n\n"
STEP=$((STEP+1));
# Étape 10: Créer un fichier .service dans .config/systemd/user/
printf "$STEP/$MAX_STEP : Création du fichier systemd service...\n"
cp $PWD/files/streamdeck.service $SYSTEMD_SERVICE_FILE
sed -i "s/VMID_LIST/$@/g" "$SYSTEMD_SERVICE_FILE" 
# Temporairement on utilise un argument pour vm_list 
# mais à terme, on aura plus d'arguements car vm_list 
# va fournir les arguments aux autres scripts

printf "$STEP/$MAX_STEP Reussie !\n\n"
STEP=$((STEP+1));
# Etape 11: Recharger les règles udev
printf "$STEP/$MAX_STEP : Rechargement des règles udev...\n";
udevadm control --reload-rules;

printf "$STEP/$MAX_STEP Reussie !\n\n";
STEP=$((STEP+1));
# Étape 12: Activer et démarrer streamdeck.path
printf "$STEP/$MAX_STEP : Activation et démarrage du chemin systemd...\n"

USER_ID=$(id -u "${SUDO_USER}")
loginctl enable-linger "$SUDO_USER"
runuser -u "${SUDO_USER}" -- bash -c "XDG_RUNTIME_DIR=/run/user/$USER_ID systemctl --user daemon-reload"
runuser -u "${SUDO_USER}" -- bash -c "XDG_RUNTIME_DIR=/run/user/$USER_ID systemctl --user enable streamdeck.path"
runuser -u "${SUDO_USER}" -- bash -c "XDG_RUNTIME_DIR=/run/user/$USER_ID systemctl --user start streamdeck.path"

printf "$STEP/$MAX_STEP Reussie !\n\n"

printf "Script terminé avec succès !\n\n"
exit 0