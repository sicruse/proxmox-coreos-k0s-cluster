data "local_file" "ssh_public_key" {
  filename = pathexpand(var.public_key)
}

resource "null_resource" "cloud_config" {

  depends_on = [
    data.local_file.ssh_public_key
  ]

  connection {
    type     = "ssh"
    user     = var.proxmox_user
    password = var.proxmox_password
    host     = var.proxmox_host
  }

  provisioner "file" {
    content = <<-EOF
    #cloud-config
    users:
      - default
      - name: ${var.ha_proxy_user}
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    runcmd:
        - apt update -y && apt dist-upgrade -y
        - apt install -y qemu-guest-agent haproxy net-tools unattended-upgrades
        - timedatectl set-timezone America/New_York
        - systemctl enable qemu-guest-agent
        - systemctl enable --now haproxy
        - systemctl start qemu-guest-agent
        - chown -R ${var.ha_proxy_user}:${var.ha_proxy_user} /etc/haproxy/
        - echo "done" > /tmp/cloud-config.done
    EOF

    destination = "${var.proxmox_snippet_storage_path}cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "haproxy" {

  depends_on = [
    null_resource.cloud_config
  ]

  name      = "haproxy"
  node_name = var.target_node

  agent {
    enabled = true
  }

  cpu {
    cores   = 2
    sockets = 2
    type    = "host"
    numa    = true
  }

  memory {
    dedicated = 2048
  }

  clone {
    node_name = var.template_node
    retries   = 3
    vm_id     = var.template_vm_id
    full      = true
  }

  initialization {
    datastore_id = var.proxmox_vm_disk_datastore_id

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_data_file_id = "${var.proxmox_snippet_datastore_id}:snippets/cloud-config.yaml"
  }

  network_device {
    model  = "virtio"
    bridge = "vmbr0"
  }

  serial_device {
    device = "socket"
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_account, # inherited from the cloned image
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
        ssh -q -o StrictHostKeyChecking=no ${var.ha_proxy_user}@$ADDRESS exit < /dev/null
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
