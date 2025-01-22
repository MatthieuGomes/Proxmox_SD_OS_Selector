#!/bin/bash
QM_LIST= $(qm list) 
# A degager
# QM_LIST=$(cat <<EOF
#      VMID NAME                 STATUS     MEM(MB)    BOOTDISK(GB) PID
#      100 debian10             running    2048               8.00 5858
#      101 debian12             running    1024              32.00 6177
#      102 ubuntu24             running    2048              32.00 113893
#      105 w7                   running    16384            100.00 279613
# EOF
# )
DECKCONFIG=""

VM_LIST_AS_STRING=""

    VM_LIST_VERTICAL=$(echo "$QM_LIST" | sed -r -e 's/([0-9]{3,4}) ([a-zA-Z0-9_]*)(.*)/\1;\2|/gm')
    VM_HEADLESS=$(echo $VM_LIST_VERTICAL | sed -r -e 's/([A-Z()]+) //g')
    VM_SPACELESS=$(echo $VM_HEADLESS | sed -r -e 's/ //g')
    VM_LIST_AS_STRING=$VM_SPACELESS;

OS_LIST=($(echo $VM_LIST_AS_STRING | sed -r -e 's/([0-9]*;)/ /g' | sed -r -e 's/(\|)//g'))
VMID_LIST=($(echo $VM_LIST_AS_STRING | sed -r -e 's/([a-zA-Z0-9]*\|)//g' | sed -r -e 's/;/ /g'))
declare -A OS_TO_VMID
for ((i=0;i<=${#OS_LIST[@]}-1;i++))
do
    KEY=${OS_LIST[$i]}
    OS_TO_VMID["$KEY"]=${VMID_LIST[$i]}
done
COUNTER=0
for KEY in ${!OS_TO_VMID[@]}
do
    OS=${KEY}
    VMID=${OS_TO_VMID["$KEY"]}
    BUTTON_CONFIG=$(<$HOME/.config/proxmox_controller/templates/vm.template)
    BUTTON_CONFIG=${BUTTON_CONFIG//§VMID§/$VMID}
    BUTTON_CONFIG=${BUTTON_CONFIG//§OS§/$OS}
    BUTTON_CONFIG=${BUTTON_CONFIG/§BUTTON_ID§/$COUNTER}
    BUTTON_CONFIG=${BUTTON_CONFIG//EOL/""}
    DECKCONFIG+=$BUTTON_CONFIG
    COUNTER=$((COUNTER+1))
done
DECKCONFIG+=$(<$HOME/.config/proxmox_controller/templates/shutdown.template)
cat <<EOF > "$HOME/.config/proxmox_controller/main.deck"
$DECKCONFIG
EOF