#
# --- Root variables.tf ---
# This file declares all input variables for the root module.

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "k8s_public_subnet_cidr1" {
  description = "The CIDR block for the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "jenkins_public_subnet_cidr2" {
  description = "The CIDR block for the jenkins public subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "k8s_private_app_subnet_cidr1" {
  description = "The CIDR block for the private application subnet."
  type        = string
  default     = "10.0.3.0/24"
}

variable "k8s_private_app_subnet_cidr2" {
  description = "The CIDR block for the private application subnet."
  type        = string
  default     = "10.0.4.0/24"
}

variable "k8s_master_instance_type" {
  description = "Instance type for the Kubernetes Master node."
  type        = string
  default     = "c7i-flex.large"
}


variable "k8s_worker_instance_type" {
  description = "Instance type for the Kubernetes Worker nodes."
  type        = string
  default     = "t3.small"
}

variable "k8s_worker_count" {
  description = "Number of Kubernetes Worker nodes."
  type        = number
  default     = 2
}

variable "k8s_master_root_volume_size" {
  description = "Size of the root EBS volume for the master node in GB."
  type        = number
  default     = 15
}

variable "k8s_worker_root_volume_size" {
  description = "Size of the root EBS volume for the worker nodes in GB."
  type        = number
  default     = 15
}

variable "jenkins_root_volume_size" {
  description = "Size of the root EBS volume for the jenkins node in GB."
  type        = number
  default     = 15
}

variable "jenkins_instance_type" {
  description = "Instance type for the jenkins node."
  type        = string
  default     = "t3.small"
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for the instances."
  type        = string
  default     = "k8s-key"
}

variable "products_bucket_name" {                                                                                                    
  description = "The name of the s3 products bucket to use for saving the prdocuts data."                                                     
  type        = string                                                                                                       
  default     = "depi-products-bucket"                                                                                                    
}                                                                                                                            


variable "ecr_repo_name_frontend" {
  description = "Name for the frontend ECR repository."
  type        = string
  default     = "depi-app-frontend"
}

variable "ecr_repo_name_backend" {
  description = "Name for the backend ECR repository."
  type        = string
  default     = "depi-app-backend"
}

