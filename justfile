# List available commands
default:
    @just --list

# Initialize Terraform
init:
    terraform init

# Validate Terraform configuration
validate:
    terraform validate

# Format Terraform files
fmt:
    terraform fmt -recursive

# Show what Terraform will do
plan:
    terraform plan

# Create/update VMs
apply:
    terraform apply

# Alias for apply
up: apply

# Destroy all VMs
destroy:
    terraform destroy

# Alias for destroy
down: destroy

# Show VM status
status:
    @terraform show -json 2>/dev/null | jq -r '.values.outputs.vm_info.value // {} | to_entries[] | "\(.key): \(.value.status) - IP: \(.value.ip)"' || echo "No VMs found. Run 'just apply' first."

# List all VMs
list:
    @virsh list --all

# SSH into a VM (usage: just ssh usvm)
ssh VM:
    #!/usr/bin/env bash
    set -euo pipefail
    IP=$(terraform output -json vm_ips 2>/dev/null | jq -r '.{{VM}} // empty')
    if [ -z "$IP" ]; then
        echo "VM '{{VM}}' not found"
        echo "Available VMs:"
        terraform output -json vm_ips 2>/dev/null | jq -r 'keys[]' || echo "No VMs found"
        exit 1
    fi
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $IP

# Show VM IP addresses
ips:
    @terraform output -json vm_ips 2>/dev/null | jq -r 'to_entries[] | "\(.key): \(.value)"' || echo "No VMs found"

# Clean Terraform state and cache
clean:
    rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

# Open virsh console (usage: just console usvm)
console VM:
    virsh console {{VM}}

# Start a stopped VM (usage: just start usvm)
start VM:
    virsh start {{VM}}

# Stop a running VM (usage: just stop usvm)
stop VM:
    virsh shutdown {{VM}}

# Restart a VM (usage: just restart usvm)
restart VM:
    virsh reboot {{VM}}

# Create a snapshot (usage: just snapshot usvm snap1)
snapshot VM NAME:
    virsh snapshot-create-as {{VM}} {{NAME}}

# List snapshots (usage: just snapshot-list usvm)
snapshot-list VM:
    virsh snapshot-list {{VM}}

# Restore a snapshot (usage: just snapshot-restore usvm snap1)
snapshot-restore VM NAME:
    virsh snapshot-revert {{VM}} {{NAME}}

# Delete a snapshot (usage: just snapshot-delete usvm snap1)
snapshot-delete VM NAME:
    virsh snapshot-delete {{VM}} {{NAME}}

# Show detailed VM info (usage: just info usvm)
info VM:
    virsh dominfo {{VM}}

# Force stop a VM (usage: just force-stop usvm)
force-stop VM:
    virsh destroy {{VM}}

# Auto-start VM on host boot (usage: just autostart usvm)
autostart VM:
    virsh autostart {{VM}}

# Disable auto-start (usage: just no-autostart usvm)
no-autostart VM:
    virsh autostart --disable {{VM}}

# Show VM console output (usage: just logs usvm)
logs VM:
    virsh console {{VM}} --force

# Run Ansible playbook on a VM (usage: just ansible usvm playbook.yml)
ansible VM PLAYBOOK:
    #!/usr/bin/env bash
    set -euo pipefail
    IP=$(terraform output -json vm_ips 2>/dev/null | jq -r '.{{VM}} // empty')
    if [ -z "$IP" ]; then
        echo "VM '{{VM}}' not found"
        exit 1
    fi
    ansible-playbook -i "${IP}," {{PLAYBOOK}}
