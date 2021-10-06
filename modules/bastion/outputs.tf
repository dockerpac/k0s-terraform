output "public_ips" {
    value = aws_instance.k0s_bastion.*.public_ip
}

output "machines" {
  value = aws_instance.k0s_bastion
}
