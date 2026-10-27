variable "proxmox_endpoint" {
  description = "Proxmox API URL, e.g. https://pve.lab:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token, in the form user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification (self-signed Proxmox cert)"
  type        = bool
  default     = true
}

variable "node_name" {
  description = "Proxmox node to create the VM on"
  type        = string
}

variable "vm_id" {
  description = "Proxmox VM ID"
  type        = number
  default     = 140
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  description = "RAM in MiB. Keep >= 2048, the nixos-anywhere kexec installer runs from RAM"
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "Disk size in GiB"
  type        = number
  default     = 32
}

variable "disk_datastore" {
  description = "Datastore for the VM disks"
  type        = string
  default     = "local-lvm"
}

variable "image_datastore" {
  description = "Datastore for the downloaded cloud image (needs the ISO content type)"
  type        = string
  default     = "local"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "vlan_id" {
  description = "VLAN tag for the NIC, null for untagged"
  type        = number
  default     = null
}

variable "flake" {
  description = "Flake to install from. Local paths only see files tracked by git"
  type        = string
  default     = null
}
