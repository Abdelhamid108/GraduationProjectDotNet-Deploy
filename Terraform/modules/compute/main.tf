# --- modules/compute/main.tf ---
# This module creates the EC2 instances.

# ------------------------------------------------------------
# SSH Key Pair
# ------------------------------------------------------------
resource "aws_key_pair" "k8s_key" {
  key_name   = var.ssh_key_name
  public_key = file("~/.ssh/DEPI_Project_rsa.pub")
}

# ------------------------------------------------------------
# IAM Roles
# ------------------------------------------------------------

# Master Role
resource "aws_iam_role" "k8s_master_role" {
  name = "k8s_master_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "k8s_master_role" }
}

# Worker Role
resource "aws_iam_role" "k8s_worker_role" {
  name = "k8s_worker_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "k8s_worker_role" }
}

# Jenkins Master Role
resource "aws_iam_role" "jenkins_master_role" {
  name = "jenkins-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "jenkins_master_role" }
}

# ------------------------------------------------------------
# POLICIES - MASTER
# ------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "k8s_master_ebs_policy" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "http" "lbc_policy_json" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "lbc_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.lbc_policy_json.response_body
}

resource "aws_iam_role_policy_attachment" "k8s_master_lbc_policy" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = aws_iam_policy.lbc_policy.arn
}

resource "aws_iam_role_policy_attachment" "k8s_master_ec2_full" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "k8s_master_ecr_policy" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "k8s_master_s3_policy" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "k8s_master_ssm_policy" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# ------------------------------------------------------------
# POLICIES - WORKER
# ------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "k8s_worker_ecr_policy" {
  role       = aws_iam_role.k8s_worker_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

 resource "aws_iam_role_policy_attachment" "k8s_worker_lbc_policy" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = aws_iam_policy.lbc_policy.arn
} 

resource "aws_iam_role_policy_attachment" "k8s_worker_ebs_csi" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role_policy_attachment" "k8s_worker_ec2_full" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
} 

resource "aws_iam_role_policy_attachment" "k8s_worker_ssm_policy" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# ------------------------------------------------------------
# Policies jenkins matser
# ------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "jenkins_master_ebs_policy" {
  role       = aws_iam_role.jenkins_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_master_ecr_policy" {
  role       = aws_iam_role.jenkins_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "jenkins_master_s3_policy" {
  role       = aws_iam_role.jenkins_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "jenkins_master_ssm_policy" {
  role       = aws_iam_role.jenkins_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# ------------------------------------------------------------
# Instance Profiles
# ------------------------------------------------------------

resource "aws_iam_instance_profile" "k8s_master_profile" {
  name = "k8s-master-profile"
  role = aws_iam_role.k8s_master_role.name
}

resource "aws_iam_instance_profile" "k8s_worker_profile" {
  name = "k8s-worker-profile"
  role = aws_iam_role.k8s_worker_role.name
}

resource "aws_iam_instance_profile" "jenkins_master_instance_profile" {
  name = "jenkins-master-instance-profile"
  role = aws_iam_role.jenkins_master_role.name
}

# ------------------------------------------------------------
# K8S MASTER NODE
# ------------------------------------------------------------

resource "aws_instance" "k8s_master" {
  ami                    = "ami-0cae6d6fe6048ca2c"
  instance_type          = var.k8s_master_instance_type
  subnet_id              = var.k8s_public_subnet_id1          # Master is public
  vpc_security_group_ids = [var.k8s_master_sg_id]
  key_name               = aws_key_pair.k8s_key.key_name

  # Root Volume
  root_block_device {
    volume_size = var.k8s_master_root_volume_size
  }
  
   metadata_options {
  http_endpoint               = "enabled"
  http_tokens                 = "optional"
  http_put_response_hop_limit = 2
  }
 
  # to enable communication between pods using the cni networking
  source_dest_check = false

  iam_instance_profile = aws_iam_instance_profile.k8s_master_profile.name

  tags = {
    Name                               = "k8s-master"
    "kubernetes.io/cluster/kubernetes" = "shared"
    "k8s.io/role/master"               = "1"
  }
}

# ------------------------------------------------------------
# EC2 WORKER NODES
# ------------------------------------------------------------

resource "aws_instance" "k8s_worker" {
  count                  = var.k8s_worker_count
  ami                    = "ami-0cae6d6fe6048ca2c"
  instance_type          = var.k8s_worker_instance_type
  subnet_id = var.private_app_subnet_ids[count.index % length(var.private_app_subnet_ids)]
  vpc_security_group_ids = [var.k8s_worker_sg_id]
  key_name               = aws_key_pair.k8s_key.key_name

  root_block_device {
    volume_size = var.k8s_worker_root_volume_size
  }
  metadata_options {
  http_endpoint               = "enabled"
  http_tokens                 = "optional"
  http_put_response_hop_limit = 2
  }

  # to enable communication between pods using the cni networking
  source_dest_check = false

  iam_instance_profile = aws_iam_instance_profile.k8s_worker_profile.name

  tags = {
    Name                               = "k8s-worker-${count.index + 1}"
    "kubernetes.io/cluster/kubernetes" = "shared"
    "k8s.io/role/node"                 = "1"
  }
}

# ------------------------------------------------------------
# EC2 Jenkins Master Node
# ------------------------------------------------------------
resource "aws_instance" "jenkins_master" {
  ami                    = "ami-0cae6d6fe6048ca2c"
  instance_type          = var.jenkins_master_instance_type
  subnet_id              = var.jenkins_public_subnet_id2          # Master is public
  vpc_security_group_ids = [var.jenkins_master_sg_id]
  key_name               = aws_key_pair.k8s_key.key_name

  # Root Volume
  root_block_device {
    volume_size = var.jenkins_master_root_volume_size
  }
  
   metadata_options {
  http_endpoint               = "enabled"
  http_tokens                 = "optional"
  http_put_response_hop_limit = 2
  }
 
  # to enable communication between pods using the cni networking
  source_dest_check = false

  iam_instance_profile = aws_iam_instance_profile.jenkins_master_instance_profile.name

  tags = {
    Name = "jenkins-control-plane"
  }
}
