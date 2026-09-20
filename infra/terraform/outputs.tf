output "vpc_id" {
  value = aws_vpc.hcn.id
}

output "vpn_gateway_instance_id" {
  value = aws_instance.vpn_gateway.id
}

output "private_app_instance_id" {
  value = aws_instance.private_app.id
}

output "private_app_ip" {
  value = aws_instance.private_app.private_ip
}

output "vpn_gateway_public_ip" {
  value = aws_instance.vpn_gateway.public_ip
}
