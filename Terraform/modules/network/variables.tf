# modules/network/variables.tf

variable "vpc_cidr" {}
variable "k8s_public_subnet_cidr1" {}
variable "jenkins_public_subnet_cidr2" {}
variable "k8s_private_app_subnet_cidr1" {}
variable "k8s_private_app_subnet_cidr2" {}
variable "aws_region" {}
