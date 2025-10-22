resource "libvirt_cloudinit_disk" "vm_init" {
  for_each = var.vms

  name = "${each.key}-cloudinit.iso"
  pool = var.pool_name
  user_data = each.value.user_data != "" ? each.value.user_data : templatefile("${path.module}/templates/cloud-init.yml.tftpl", {
    hostname            = "${each.key}-${var.hostname_suffix}"
    ssh_authorized_keys = concat(var.ssh_authorized_keys, each.value.ssh_keys)
    enable_ansible      = each.value.enable_ansible
  })
}
