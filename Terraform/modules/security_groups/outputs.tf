# modules/security_groups/outputs.tf

output "k8s_master_sg_id" { value = aws_security_group.k8s_master_sg.id }
output "k8s_worker_sg_id" { value = aws_security_group.k8s_worker_sg.id }
output "jenkins_sg_id" { value = aws_security_group.jenkins_master_sg.id }
