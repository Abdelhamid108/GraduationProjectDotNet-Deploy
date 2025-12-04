# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
}

# Create a Key Pair using an existing public key on the local machine
resource "aws_key_pair" "devops_ema2a" {
  key_name   = "ema2a_ssh_key"
  public_key = file("~/.ssh/ema2a.pub")
}

# Create an EC2 Instance
resource "aws_instance" "ema2a_server" {
  ami           = "ami-0fa3fe0fa7920f68e" # Ubuntu AMI (Verify region/OS)
  instance_type = "c7i-flex.large"
  key_name      = aws_key_pair.devops_ema2a.key_name
  
  root_block_device {
    volume_size = 20
  }
  # Attach the Security Group
  vpc_security_group_ids = [aws_security_group.ema2a_sg.id]
  tags = {
       Name = "Ema2a-Server"
  }
}

# Create an Elastic IP (EIP) and associate it with the instance
# This ensures the instance has a static public IP address
resource "aws_eip" "ema2a_public_ip" {
  instance = aws_instance.ema2a_server.id
  domain   = "vpc"
}

# Create a Security Group to control traffic
resource "aws_security_group" "ema2a_sg" {
  name        = "ema2a_server_sg"
  description = "Security Group For ema2a Server"

  tags = {
    Name = "ema2a-sg"
  }
}

# Security Group Rule: Allow HTTP (Port 80) from anywhere
resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ema2a_sg.id
}

# Security Group Rule: Allow HTTPS (Port 443) from anywhere
resource "aws_security_group_rule" "allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ema2a_sg.id
}

# Security Group Rule: Allow Jenkins (Port 8080) from anywhere
resource "aws_security_group_rule" "allow_jenkins" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ema2a_sg.id
}

# Security Group Rule: Allow SSH (Port 22) from anywhere
# WARNING: Allowing SSH from 0.0.0.0/0 is a security risk. Consider restricting to your IP.
resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ema2a_sg.id
}

# Security Group Rule: Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # -1 means all protocols
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ema2a_sg.id
}

# Output the Elastic IP of the server
output "ema2a_server_ip" { 
  value       = aws_eip.ema2a_public_ip.public_ip
  description = "The public IP address of the ema2a server"
}


