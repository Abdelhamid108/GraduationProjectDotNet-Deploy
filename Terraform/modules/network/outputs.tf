# modules/network/outputs.tf
output "vpc_id" {
  value = aws_vpc.k8s_vpc.id
}

output "k8s_public_subnet_id1" {
  value = aws_subnet.k8s_public_subnet.id
}

output "jenkins_public_subnet_id2" {
  value = aws_subnet.jenkins_public_subnet.id
}

output "k8s_private_app_subnet_id1" {
  value = aws_subnet.k8s_private_app_subnet1.id
}

output "k8s_private_app_subnet_id2" {
  value = aws_subnet.k8s_private_app_subnet2.id
}

