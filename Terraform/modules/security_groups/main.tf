#
# --- modules/security_groups/main.tf ---
# This module creates the security groups for master and worker nodes.
# ==========================================
# 1. Security Group Definitions 
# ==========================================

resource "aws_security_group" "k8s_master_sg" {
  name        = "k8s-master-sg"
  description = "Security Group for Kubernetes Master"
  vpc_id      = var.vpc_id

  tags = {
    Name = "k8s-master-sg"
    "kubernetes.io/cluster/kubernetes" = "shared"
  }
}

resource "aws_security_group" "k8s_worker_sg" {
  name        = "k8s-worker-sg"
  description = "Security Group for Kubernetes Workers"
  vpc_id      = var.vpc_id

  tags = {
    Name = "k8s-worker-sg"
    "kubernetes.io/cluster/kubernetes" = "shared"
  }
}

resource "aws_security_group" "jenkins_master_sg" {
  name        = "jenkins-master-sg"
  description = "security group for jenkins master"
  vpc_id      = var.vpc_id

  tags = {
    Name = "jenkins-master-sg"
  }
}

# ==========================================
# 2. Egress Rules (Allow all outbound traffic)
# ==========================================

resource "aws_security_group_rule" "k8s_master_egress" {
  type              = "egress"
  security_group_id = aws_security_group.k8s_master_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "k8s_worker_egress" {
  type              = "egress"
  security_group_id = aws_security_group.k8s_worker_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "jenkins_master_egress" {
  type              = "egress"
  security_group_id = aws_security_group.jenkins_master_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ==========================================
# 3. Master Node Ingress Rules
# ==========================================

# Allow SSH access
resource "aws_security_group_rule" "k8s_master_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_master_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow Jenkins access
resource "aws_security_group_rule" "k8s_master_jenkins" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_master_sg.id
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow ALL traffic from Workers (Required for API Server, Etcd, and Calico)
resource "aws_security_group_rule" "k8s_master_from_workers" {
  type                     = "ingress"
  security_group_id        = aws_security_group.k8s_master_sg.id
  source_security_group_id = aws_security_group.k8s_worker_sg.id
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  description              = "Allow all traffic from workers"
}

# ==========================================
# 4. Worker Node Ingress Rules
# ==========================================

# Allow ALL traffic from Master (For control plane communication)
resource "aws_security_group_rule" "k8s_worker_from_master" {
  type                     = "ingress"
  security_group_id        = aws_security_group.k8s_worker_sg.id
  source_security_group_id = aws_security_group.k8s_master_sg.id
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  description              = "Allow all traffic from master"
}

# Allow workers to communicate with each other (Pod-to-Pod communication)
resource "aws_security_group_rule" "k8s_worker_from_self" {
  type                     = "ingress"
  security_group_id        = aws_security_group.k8s_worker_sg.id
  source_security_group_id = aws_security_group.k8s_worker_sg.id
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  description              = "Allow workers to talk to each other (Pod-to-Pod)"
}

# Allow external Load Balancers to access NodePorts
# This is the rule that enables the Classic Load Balancer to reach your pods
resource "aws_security_group_rule" "k8s_worker_nodeports" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_worker_sg.id
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow external Load Balancers to access NodePorts"
}

# Allow jenkins master  to access k8s_workers
resource "aws_security_group_rule" "jenkins_worker_ssh" {
  type                     = "ingress"
  security_group_id        = aws_security_group.k8s_worker_sg.id
  source_security_group_id = aws_security_group.jenkins_master_sg.id
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  description              = "Allow external Jenkins Master to connect to k8s_workers using ssh"
}



# ==========================================
# 5. Jenkins Master Ingress Rules
# ==========================================

# Allow SSH access
resource "aws_security_group_rule" "jenkins_master_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.jenkins_master_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow Jenkins access
resource "aws_security_group_rule" "jenkins_master_jenkins" {
  type              = "ingress"
  security_group_id = aws_security_group.jenkins_master_sg.id
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
} 

# Allow Ports for communication between jenkins master and jenkins agents
resource "aws_security_group_rule" "jenkins_master_jenkins_agents" {
  type              = "ingress"
  security_group_id = aws_security_group.jenkins_master_sg.id
  from_port         = 50000
  to_port           = 50000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow Ports for using Kubernetes API server   
resource "aws_security_group_rule" "jenkins_master_k8s_api" {
  type              = "ingress"
  security_group_id = aws_security_group.jenkins_master_sg.id
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
