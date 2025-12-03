# modules/compute/variables.tf

variable "k8s_master_instance_type" {}
variable "k8s_worker_instance_type" {}
variable "k8s_worker_count" {}
variable "ssh_key_name" {}
variable "k8s_public_subnet_id1" {}
variable "k8s_master_sg_id" {}
variable "k8s_worker_sg_id" {}
variable "k8s_master_root_volume_size" {}
variable "k8s_worker_root_volume_size" {}
variable "jenkins_master_instance_type" {}
variable "jenkins_public_subnet_id2" {}
variable "jenkins_master_sg_id" {}
variable "jenkins_master_root_volume_size" {}
variable "private_app_subnet_ids" {
  type = list(string)
}
