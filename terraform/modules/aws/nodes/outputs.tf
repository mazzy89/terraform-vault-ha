output "private_ips" {
  value = aws_instance.nodes[*].private_ip
}
