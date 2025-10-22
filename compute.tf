resource "libvirt_domain" "vms" {
  for_each = var.vms

  name      = each.key
  memory    = each.value.memory
  vcpu      = each.value.cpus
  autostart = each.value.autostart

  cloudinit = libvirt_cloudinit_disk.vm_init[each.key].id

  disk {
    volume_id = libvirt_volume.vm_disks[each.key].id
  }

  network_interface {
    network_id     = libvirt_network.vm_network.id
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for ${each.key} to be ready..."
      timeout 300 bash -c 'until nc -z ${self.network_interface[0].addresses[0]} 22 2>/dev/null; do sleep 2; done' || true
    EOT
  }
}
