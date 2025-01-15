#!/bin/sh
# Inserez ici la commande proxmox
# Command proxmox pour :
# Obtenir la liste des VMs dispo
# Generer les différentes pour lancer les VMs
# Generer les assets pour les VMs
FREE_VMIDS="$@"
echo "free VMIDS $FREE_VMIDS"
/bin/bash $HOME/.config/proxmox_controller/create.sh $FREE_VMIDS
deckmaster -deck $HOME/.config/proxmox_controller/main.deck