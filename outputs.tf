output "mini_server_public_ip" {
  value = aws_instance.mini-server.public_ip
}
output "instance_id" {
  value = aws_instance.mini-server.id
}
output "vpc_id" {
  value = aws_vpc.main.id
}