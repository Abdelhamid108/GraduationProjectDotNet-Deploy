#
# --- Root outputs.tf ---
# This file declares outputs from the root module.
# These values are printed after 'terraform apply' and can be queried.

output "k8s_master_public_ip" {
  description = "Public IP address of the Kubernetes Master Node."
  # Value is taken from the output of the 'compute' module
  value       = module.compute.k8s_master_public_ip
}
output "jenkins_master_public_ip" {
  description = "public ip address of the jenkins control plane"
  value = module.compute.jenkins_master_public_ip
}

output "k8s_worker_private_ips" {
  description = "Private IP addresses of the Kubernetes Worker Nodes."
  value       = module.compute.k8s_worker_private_ips
}

output "frontend_ecr_repo_url" {
  description = "URL of the Frontend ECR Repository."
  value       = module.ecr_repos.frontend_repo_url
}

output "backend_ecr_repo_url" {
  description = "URL of the Backend ECR Repository."
  value       = module.ecr_repos.backend_repo_url
}

