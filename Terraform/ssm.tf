# ssm using to save the dynamic values that jenkins use to deploy app

resource "aws_ssm_parameter" "backend_ecr" {
  name        = "/depi-project/amazona/backend-ecr"
  description = "This is url for backend ecr repo"
  type        = "String"
  value       = module.ecr_repos.backend_repo_url

}

resource "aws_ssm_parameter" "frontend_ecr" {
  name        = "/depi-project/amazona/frontend-ecr"
  description = "This is url for frontend ecr repo"
  type        = "String"
  value       = module.ecr_repos.frontend_repo_url
}

resource "aws_ssm_parameter" "s3_bucket_name" {
  name        = "/depi-project/amazona/products-bucket"
  description = "This is url for s3 bucket used to save products data"
  type        = "String"
  value       = module.s3.app_s3_bucket_name
}
