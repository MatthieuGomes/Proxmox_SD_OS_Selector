#!/bin/sh
# Inserez ici la commande proxmox
# Command proxmox pour :
# Obtenir la liste des VMs dispo
# Generer les différentes pour lancer les VMs
# Generer les assets pour les VMs
FREE_VMIDS="$@"
/bin/bash $PROXMOX_CONTROLLER_PATH/create.sh $FREE_VMIDS
deckmaster -deck $PROXMOX_CONTROLLER_PATH/main.deck