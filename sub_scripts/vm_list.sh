#!/bin/bash

VM_LIST=($@);
echo "VM list arguments $@"
echo "VM list arguments via variable $VM_LIST"

return $VM_LIST;