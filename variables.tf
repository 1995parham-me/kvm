variable "vms" {
  description = "Map of VMs to create"
  type = map(object({
    memory         = number
    cpus           = number
    disk_size      = number # in GB
    image_url      = string
    autostart      = optional(bool, false)
    ssh_keys       = optional(list(string), [])
    user_data      = optional(string, "")
    enable_ansible = optional(bool, false)
  }))
}

variable "pool_name" {
  description = "Storage pool name"
  type        = string
  default     = "default"
}

variable "network_name" {
  description = "Network name"
  type        = string
  default     = "default"
}

variable "hostname_suffix" {
  description = "Suffix for VM hostnames"
  type        = string
  default     = "1995parham-infra"
}

variable "ssh_authorized_keys" {
  description = "SSH public keys to add to VMs"
  type        = list(string)
  default     = []
}
