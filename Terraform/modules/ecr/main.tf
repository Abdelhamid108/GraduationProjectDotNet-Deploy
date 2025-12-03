#
# --- modules/ecr/main.tf ---
# This module creates the ECR repositories.

# Create the Frontend ECR Repository
resource "aws_ecr_repository" "frontend_repo" {
  name                 = var.ecr_repo_name_frontend
  image_tag_mutability = "MUTABLE" # Allows image tags to be overwritten
  image_scanning_configuration {
    scan_on_push = true # Automatically scan images for vulnerabilities
  }
  tags = { Name = "Frontend_ECR_Repo" }
}

# Create the Backend ECR Repository
resource "aws_ecr_repository" "backend_repo" {
  name                 = var.ecr_repo_name_backend
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = { Name = "Backend_ECR_Repo" }
}
