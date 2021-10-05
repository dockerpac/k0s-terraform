output "lb_dns_name" {
    value = aws_lb.k0s_controller.dns_name
}

output "public_ips" {
    value = aws_instance.k0s_controller.*.public_ip
}

output "private_ips" {
    value = aws_instance.k0s_controller.*.private_ip
}

output "machines" {
  value = aws_instance.k0s_controller
}
