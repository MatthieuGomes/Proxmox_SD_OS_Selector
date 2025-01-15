#!/bin/bash
ARG_LIST=($@)
NUM_ARGS=$#
DECKCONFIG=""
echo "test list arguments $@"

for ((i=0;i<=$NUM_ARGS-1;i++))
do
    VMID=${ARG_LIST[$i]}
    BUTTON_CONFIG=$(<$HOME/.config/proxmox_controller/templates/vm.template)
    BUTTON_CONFIG=${BUTTON_CONFIG//VMID/$VMID}
    BUTTON_CONFIG=${BUTTON_CONFIG/BUTTON_ID/$i}
    BUTTON_CONFIG=${BUTTON_CONFIG//EOL/""}
    DECKCONFIG+=$BUTTON_CONFIG   
done
DECKCONFIG+=$(<$HOME/.config/proxmox_controller/templates/shutdown.template)
cat <<EOF > "$HOME/.config/proxmox_controller/main.deck"
$DECKCONFIG
EOF