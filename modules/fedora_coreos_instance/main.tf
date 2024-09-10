

resource "proxmox_virtual_environment_vm" "fedora_coreos_instance" {
  name          = var.name
  on_boot       = var.autostart
  node_name     = var.target_node
  scsi_hardware = "virtio-scsi-pci"
  kvm_arguments = "-fw_cfg name=opt/com.coreos/config,file=${var.snippet_storage_path}ignition_${var.name}.ign"

  memory {
    dedicated = var.memory
    floating  = var.memory
  }

  cpu {
    cores   = var.vcpus
    type    = "host"
    sockets = var.sockets
  }

  agent {
    enabled = true
    timeout = "600s"
  }

  clone {
    node_name = var.template_node
    retries = 3
    vm_id   = var.template_vm_id
    full    = true
  }

  network_device {
    model  = "virtio"
    bridge = var.default_network_bridge
  }

  lifecycle {
    ignore_changes = [ 
      vga,
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
      n=0
      until [ "$n" -ge 10 ]
      do
        echo "Attempt number: $n"
        ssh-keygen -R $ADDRESS
        if [ $? -eq 0 ]; then
          echo "Successfully removed $ADDRESS"
          break
        fi
        n=$((n+1)) 
        sleep $(( ( RANDOM % 10 ) + 1 ))s      
      done
    EOT
    environment = {
      ADDRESS = element(flatten(self.ipv4_addresses), 1)
    }
    when = destroy
  }

  provisioner "local-exec" {
    command = <<-EOT
      n=0
      until [ "$n" -ge 10 ]
      do
        echo "Attempt number: $n"
        ssh-keyscan -H $ADDRESS >> ~/.ssh/known_hosts
        ssh -q -o StrictHostKeyChecking=no core@$ADDRESS exit < /dev/null
        if [ $? -eq 0 ]; then
          echo "Successfully added $ADDRESS"
          break
        fi
        n=$((n+1)) 
        sleep $(( ( RANDOM % 10 ) + 1 ))s
      done
    EOT
    environment = {
      ADDRESS = element(flatten(self.ipv4_addresses), 1)
    }
    when = create
  }
}
