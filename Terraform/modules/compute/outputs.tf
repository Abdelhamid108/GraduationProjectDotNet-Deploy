# modules/compute/outputs.tf

output "k8s_master_public_ip" { value = aws_instance.k8s_master.public_ip }
output "k8s_worker_private_ips" { value = [for instance in aws_instance.k8s_worker : instance.private_ip] }
output "jenkins_master_public_ip"    { value = aws_instance.jenkins_master.public_ip }
