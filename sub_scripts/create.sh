#!/bin/bash
ARG_LIST=($@)
NUM_ARGS=$#
DECKCONFIG=""
echo "test list arguments $@"

for ((i=0;i<=$NUM_ARGS-1;i++))
do
    VMID=${ARG_LIST[$i]}
    if [ $i = 0 ]
    then DECKCONFIG+=$(cat <<DELIMITER
[[keys]]
    index = $i
    [keys.widget]
        id = "button"
        [keys.widget.config]
            icon = "assets/$VMID.png"
            label = "$VMID"
            fontsize = 8
        [keys.action]
            command = "qm start $VMID"
DELIMITER
)
    else
DECKCONFIG+=$(cat <<DELIMITER

[[keys]]
    index = $i
    [keys.widget]
        id = "button"
        [keys.widget.config]
            icon = "assets/$VMID.png"
            label = "$VMID"
            fontsize = 8
        [keys.action]
            command = "qm start $VMID"
DELIMITER
)
fi
done

if [ $NUM_ARGS = 0 ] 
then DECKCONFIG+=$(cat <<DELIMITER
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
DECKCONFIG+=$(cat <<DELIMITER

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
$DECKCONFIG
EOF