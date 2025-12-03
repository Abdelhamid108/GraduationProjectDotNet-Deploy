# modules/ecr/outputs.tf

output "frontend_repo_url" {
  description = "URL of the Frontend ECR Repository."
  value       = aws_ecr_repository.frontend_repo.repository_url
}

output "backend_repo_url" {
  description = "URL of the Backend ECR Repository."
  value       = aws_ecr_repository.backend_repo.repository_url
}
