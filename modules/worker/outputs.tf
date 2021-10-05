output "private_ips" {
    value = aws_instance.k0s_worker.*.private_ip
}
output "machines" {
  value = aws_instance.k0s_worker.*
}
