output "ip" {
  value = local.ip
}

output "ssh" {
  value = "ssh evan@${local.ip}"
}
