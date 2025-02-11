#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root to modify /etc/hosts."
    exit 1
fi

# Check if a tag value is provided
if [ "$#" -ne 3 ]; then
   echo "Usage: $0 <resource-group-name> <tag-value>"
   echo "Example: $0 worker myrg ./inventory.yml "
   exit 1
fi

RESOURCE_GROUP=$2
TAG_VALUE=$1
USER=$(logname)  # Get the current logged-in user
INVENTORY_FILE=$3  # Replace with the path to your inventory file

# Check if 'all' is selected and adjust the query accordingly
if [ "$TAG_VALUE" == "all" ]; then
    echo "Fetching VMs with tags 'worker' and 'master' for resource group '$RESOURCE_GROUP'..."
    VM_DATA=$(sudo -u $USER az vm list -d --query "[?tags.\"virtualmachine-type\"=='worker' || tags.\"virtualmachine-type\"=='master'].[name,publicIps,tags.\"virtualmachine-type\"]" --resource-group "$RESOURCE_GROUP" -o tsv)
else
    echo "Fetching VMs with tag: $TAG_VALUE..."
    VM_DATA=$(sudo -u $USER az vm list -d --query "[?tags.\"virtualmachine-type\"=='$TAG_VALUE'].[name,publicIps,tags.\"virtualmachine-type\"]" --resource-group "$RESOURCE_GROUP" -o tsv)
fi

# Check if any data was returned
if [ -z "$VM_DATA" ]; then
    echo "No VMs found with the tag value '$TAG_VALUE' in resource group '$RESOURCE_GROUP'."
    exit 0
fi

# Backup /etc/hosts before modifying
cp /etc/hosts /etc/hosts.bak

# Ensure the Ansible inventory file has [masters] and [workers] headers
if ! grep -q "^\[master\]" "$INVENTORY_FILE"; then
    echo -e "\n[master]" >> "$INVENTORY_FILE"
fi
if ! grep -q "^\[workers\]" "$INVENTORY_FILE"; then
    echo -e "\n[workers]" >> "$INVENTORY_FILE"
fi

# Ensure the /etc/hosts has [kube] header

if ! grep -q "^\[kube\]" "/etc/hosts"; then
    sudo sed -i -e '$a\\n[kube]\n' /etc/hosts
fi

# Empty existing datas
sed -i '/^\(worker\|master\)[0-9]/d' $INVENTORY_FILE
sed -i '/\(worker[0-9]*\)\|master$/d' /etc/hosts


# Function to insert lines under a specific group in the inventory file
insert_into_file() {
    local group=$1
    local line=$2
    local file=$3
    # Find the line number of the group header
    local group_line=$(grep -n "^\[$group\]" "$3" | cut -d: -f1)
    if [ -n "$group_line" ]; then
        # Find the next non-empty line or end of file
        local insert_line=$(awk "NR>$group_line && NF==0 {print NR; exit}" "$3")
        if [ -z "$insert_line" ]; then
            insert_line=$(wc -l < "$3")
        fi
        # Insert the new line
        sed -i "${insert_line}i $line" "$3"
    fi
}

# Append VM data to /etc/hosts and inventory
echo "Updating /etc/hosts and Ansible inventory..."
counter_master=1
counter_worker=1
while IFS=$'\t' read -r NAME IP TAGS; do
    if [ -n "$IP" ]; then
        # Add entries to inventory and /etc/hosts
        # !!!!!!!!! ansible_ssh_common_args='-o StrictHostKeyChecking=no' for dev use only => man in the middle breach !!!!!!!!!
        if [ "$TAG_VALUE" == "worker" ] || { [ "$TAG_VALUE" == "all" ] && [[ "$TAGS" == "worker" ]]; }; then
            insert_into_file "kube" "$IP $NAME worker$counter_worker" "/etc/hosts"
            insert_into_file "workers" "worker$counter_worker ansible_host=$IP ansible_user=azureadm ansible_ssh_common_args='-o StrictHostKeyChecking=no'" "$INVENTORY_FILE"
            ((counter_worker++))
        fi
        if [ "$TAG_VALUE" == "master" ] || { [ "$TAG_VALUE" == "all" ] && [[ "$TAGS" == "master" ]]; }; then
            #echo "$IP master$counter_master" >> /etc/hosts
            insert_into_file "kube" "$IP $NAME master" "/etc/hosts"
            insert_into_file "master" "master$counter_master ansible_host=$IP ansible_user=azureadm ansible_ssh_common_args='-o StrictHostKeyChecking=no'" "$INVENTORY_FILE"
            ((counter_master++))
        fi
    fi
done <<< "$VM_DATA"

echo "Done! The following entries were added to /etc/hosts and Ansible inventory:"
echo "$VM_DATA"

