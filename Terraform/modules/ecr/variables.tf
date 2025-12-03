# modules/ecr/variables.tf

variable "ecr_repo_name_frontend" {
  description = "Name for the frontend ECR repository."
  type        = string
}

variable "ecr_repo_name_backend" {
  description = "Name for the backend ECR repository."
  type        = string
}
