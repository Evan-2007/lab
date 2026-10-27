locals {
  vm    = jsondecode(file("${path.module}/../../nixos/hosts/dococd-test/vm.json"))
  ip    = split("/", local.vm.address)[0]
  flake = coalesce(var.flake, abspath("${path.module}/../.."))
}

resource "proxmox_download_file" "debian" {
  node_name    = var.node_name
  datastore_id = var.image_datastore
  content_type = "iso"
  url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
  file_name    = "debian-13-genericcloud-amd64.img"
}

resource "proxmox_virtual_environment_vm" "dococd_test" {
  name      = local.vm.hostname
  node_name = var.node_name
  vm_id     = var.vm_id
  tags      = ["nixos", "test"]

  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
    wait_for_ip {
      disabled = true
    }
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  efi_disk {
    datastore_id = var.disk_datastore
    type         = "4m"
  }

  disk {
    datastore_id = var.disk_datastore
    file_id      = proxmox_download_file.debian.id
    interface    = "scsi0"
    size         = var.disk_size
    iothread     = true
    discard      = "on"
  }

  network_device {
    bridge  = var.bridge
    vlan_id = var.vlan_id
  }

  initialization {
    datastore_id = var.disk_datastore

    ip_config {
      ipv4 {
        address = local.vm.address
        gateway = local.vm.gateway
      }
    }

    dns {
      servers = [local.vm.dns]
    }

    user_account {
      username = "debian"
      keys     = local.vm.ssh_authorized_keys
    }
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [initialization, disk[0].file_id]
  }
}

module "nixos" {
  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one?ref=1.13.0"

  nixos_system_attr      = "${local.flake}#nixosConfigurations.dococd-test.config.system.build.toplevel"
  nixos_partitioner_attr = "${local.flake}#nixosConfigurations.dococd-test.config.system.build.diskoScript"

  target_host  = local.ip
  install_user = "debian"
  target_user  = "evan"

  instance_id = proxmox_virtual_environment_vm.dococd_test.id

  depends_on = [proxmox_virtual_environment_vm.dococd_test]
}
