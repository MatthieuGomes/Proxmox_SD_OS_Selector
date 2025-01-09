#!/bin/bash

# Variables
USER_HOME=$(eval echo ~${SUDO_USER})
PACKAGE_URL="https://github.com/muesli/deckmaster/releases/download/v0.9.0/deckmaster_0.9.0_linux_amd64.deb" # Remplacez par le lien du package
PACKAGE_NAME=$(basename "$PACKAGE_URL") # Nom du package extrait du lien
UDEV_RULES_FILE="/etc/udev/rules.d/99-streamdeck.rules"
SYSTEMD_PATH_FILE="$USER_HOME/.config/systemd/user/streamdeck.path"
SYSTEMD_SERVICE_FILE="$USER_HOME/.config/systemd/user/streamdeck.service"
PROXMOX_CONTROLLER_PATH="$USER_HOME/.config/proxmox_controller"

# Vérifier si le script est exécuté avec les droits root pour certaines étapes
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root pour certaines étapes (e.g., création de fichiers dans /etc/udev)."
  exit 1
fi

# Etape 4: Création du fichier start.sh
echo "Création du fichier start.sh..."
mkdir -p "$PROXMOX_CONTROLLER_PATH"
chown $SUDO_USER "$PROXMOX_CONTROLLER_PATH"
cat <<EOF1 > "$PROXMOX_CONTROLLER_PATH/start.sh"
#!/bin/sh
# Inserez ici la commande proxmox
# Command proxmox pour :
# Obtenir la liste des VMs dispo
# Generer les différentes pour lancer les VMs
# Generer les assets pour les VMs
FREE_VMIDS="$@"
/bin/bash $PROXMOX_CONTROLLER_PATH/create.sh \$FREE_VMIDS
deckmaster -deck $PROXMOX_CONTROLLER_PATH/main.deck
EOF1
chmod +x "$PROXMOX_CONTROLLER_PATH/start.sh"

cp -r -R $PWD/icons "$PROXMOX_CONTROLLER_PATH/assets"

cat <<EOF2 > "$PROXMOX_CONTROLLER_PATH/create.sh"
#!/bin/bash
ARG_LIST=(\$@)
NUM_ARGS=\$#
DECKCONFIG=""
echo "test list arguments \$@"

for ((i=0;i<=\$NUM_ARGS-1;i++))
do
    VMID=\${ARG_LIST[\$i]}
    if [ \$i = 0 ]
    then DECKCONFIG+=\$(cat <<DELIMITER
[[keys]]
    index = \$i
    [keys.widget]
        id = "button"
        [keys.widget.config]
            icon = "assets/\$VMID.png"
            label = "\$VMID"
            fontsize = 8
        [keys.action]
            command = "qm start \$VMID"
DELIMITER
)
    else
DECKCONFIG+=\$(cat <<DELIMITER

[[keys]]
    index = \$i
    [keys.widget]
        id = "button"
        [keys.widget.config]
            icon = "assets/\$VMID.png"
            label = "\$VMID"
            fontsize = 8
        [keys.action]
            command = "qm start \$VMID"
DELIMITER
)
fi
done

if [ \$NUM_ARGS = 0 ] 
then DECKCONFIG+=\$(cat <<DELIMITER
[[keys]]
    index = 5
    [keys.widget]
        id = "button"
        [keys.widget.config]
            icon = "assets/shutdown.png"
            label = "shutdown"
            fontsize = 8
        [keys.action]
            command = "shutdown -h now"
DELIMITER
)
else
DECKCONFIG+=\$(cat <<DELIMITER

[[keys]]
    index = 5
    [keys.widget]
        id = "button"
        [keys.widget.config]
            icon = "assets/shutdown.png"
            label = "shutdown"
            fontsize = 8
        [keys.action]
            command = "shutdown -h now"
DELIMITER
)
fi

cat <<EOF > "$PROXMOX_CONTROLLER_PATH/main.deck"
\$DECKCONFIG
EOF
EOF2
chmod +x "$PROXMOX_CONTROLLER_PATH/create.sh"
# Etape 5: Création du fichier de génération de fichier deck

# Étape 1: Télécharger et installer le package
echo "Téléchargement et installation du package..."
wget -O "/tmp/$PACKAGE_NAME" "$PACKAGE_URL"
apt install -y "/tmp/$PACKAGE_NAME"
rm "/tmp/$PACKAGE_NAME"

# Étape 2: Créer un fichier .rules dans /etc/udev/rules.d/
echo "Création du fichier udev rules..."
cat <<EOL > "$UDEV_RULES_FILE"
# Version 1
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0060", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck"

# Version 2
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006d", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck"

# Version 3
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0080", MODE:="666", GROUP:="plugdev", SYMLINK+="streamdeck"

# Version mini
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0063", MODE:="0660",GROUP="plugdev", SYMLINK+="streamdeck-mini"

# Version xl
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006c", MODE:="0660", GROUP="plugdev", SYMLINK+="streamdeck-xl"
EOL

echo "Changement des permissions pour /dev/uinput..."
chown root:plugdev /dev/uinput

# Étape 3: Créer un fichier .path dans .config/systemd/user/
echo "Création du fichier systemd path..."
cat <<EOL > "$SYSTEMD_PATH_FILE"
[Unit]
Description="Stream Deck Device Path"

[Path]
# the device name will be different if you use streamdeck-mini or streamdeck-xl
PathExists=/dev/streamdeck-mini
Unit=streamdeck.service

[Install]
WantedBy=default.target
EOL



# Étape 4: Créer un fichier .service dans .config/systemd/user/
echo "Création du fichier systemd service..."
cat <<EOL > "$SYSTEMD_SERVICE_FILE"
[Unit]
Description=Deckmaster Service

[Service]
# adjust the path to deckmaster and .deck file to suit your needs
ExecStart=/bin/sh $PROXMOX_CONTROLLER_PATH/start.sh $PROXMOX_CONTROLLER_PATH
ExecReload=kill -HUP $MAINPID

[Install]
WantedBy=default.target
EOL

# Etape 5: Recharger les règles udev

udevadm control --reload-rules

# Étape 5: Activer et démarrer streamdeck.path
echo "Activation et démarrage du chemin systemd..."

USER_ID=$(id -u "${SUDO_USER}")
loginctl enable-linger "$SUDO_USER"
runuser -u "${SUDO_USER}" -- bash -c "XDG_RUNTIME_DIR=/run/user/$USER_ID systemctl --user daemon-reload"
runuser -u "${SUDO_USER}" -- bash -c "XDG_RUNTIME_DIR=/run/user/$USER_ID systemctl --user enable streamdeck.path"
runuser -u "${SUDO_USER}" -- bash -c "XDG_RUNTIME_DIR=/run/user/$USER_ID systemctl --user start streamdeck.path"

echo "Script terminé avec succès !"
exit 0