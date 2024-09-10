output "address" {
  value       = element(flatten(proxmox_virtual_environment_vm.fedora_coreos_instance.ipv4_addresses), 1)
  description = "Non-local IP Address of the Fedora CoreOS instance"
}

output "name" {
  value       = proxmox_virtual_environment_vm.fedora_coreos_instance.name
  description = "Name of the Fedora CoreOS instance"
}