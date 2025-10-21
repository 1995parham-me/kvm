output "vm_ips" {
  description = "IP addresses of created VMs"
  value = {
    for name, vm in libvirt_domain.vms :
    name => try(vm.network_interface[0].addresses[0], "pending...")
  }
}

output "vm_info" {
  description = "Detailed VM information"
  value = {
    for name, vm in libvirt_domain.vms :
    name => {
      id     = vm.id
      ip     = try(vm.network_interface[0].addresses[0], "pending...")
      memory = vm.memory
      vcpu   = vm.vcpu
      status = vm.running ? "running" : "stopped"
    }
  }
}

output "ssh_commands" {
  description = "SSH commands to connect to VMs"
  value = {
    for name, vm in libvirt_domain.vms :
    name => "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${try(vm.network_interface[0].addresses[0], "PENDING")}"
  }
}
