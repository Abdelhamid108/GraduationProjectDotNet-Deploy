
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 5.0" }
    infisical = { source = "infisical/infisical" }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "infisical" {
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

# Fetch all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ema2a_ami" {
  owners = ["self"]
 
  filter {
    name   = "tag:Project"
    values = ["ema2a"]
  }
  
  filter {
    name   = "tag:Component"
    values = ["server-ami"]
  }
  
}

# Create a Key Pair using an existing public key on the local machine
resource "aws_key_pair" "devops_ema2a" {
  key_name   = "ema2a_ssh_key"
  public_key = file("~/.ssh/ema2a.pub")
}

# Create an Empty role for instance to use when fetching secrets
module "iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"

  name = "ema2a-instance-profile"
  
  create_instance_profile = true

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
      principals = [
        {
          type = "Service"
          identifiers = [
            "ec2.amazonaws.com",
          ]
        }
      ]
    }
  }
  
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "ema2a"
  }
}

module "ec2_instance" {
  ami = data.aws_ami.ema2a_ami.id
  create = true 
   
  subnet_id = data.aws_subnets.default.ids[0]

  source  = "terraform-aws-modules/ec2-instance/aws"
  associate_public_ip_address = true
  name = "ema2a-backup-deployment-server"
  
  create_eip             = true
  iam_instance_profile   = module.iam_role.instance_profile_name
  instance_type          = var.instance_type
  key_name               = aws_key_pair.devops_ema2a.key_name
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.ema2a_sg.id]
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "ema2a"
  }
  root_block_device = {
    size       = var.instance_root_volume_size
  }
}


module "alarm_metric_query" {
  source = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"

  alarm_name          = "auto stop ec2"
  alarm_description   = "Alarm For Stoping the server if there is no traffic"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  threshold           = 2


      namespace   = "AWS/EC2"
      metric_name = "CPUUtilization"
      period      = 300
      statistic   = "Average"
      dimensions  = {
        InstanceId = module.ec2_instance.id
      }

  alarm_actions = ["arn:aws:automate:us-east-1:ec2:stop"]

  tags = {
    Project = "ema2a" 
  }
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

module "iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "ema2a-lambda-function"
  path        = "/"
  description = "Function to start ema2a server"

  policy = <<-EOF
     {
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"ec2:StartInstances",
				"ec2:StopInstances"
			],
			"Resource": "${module.ec2_instance.arn}"
		},
		{
			"Sid": "VisualEditor1",
			"Effect": "Allow",
			"Action": "ec2:DescribeInstances",
			"Resource": "*"
		}
	]
    }  
  EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "ema2a"
  }
}

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "ema2a-lambda"
  description   = "Lambda Function To start Deployment server"
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  source_path = "./lambda_src"
  
  publish       = true
  create_role   = true
  attach_policy = true
  policy        = module.iam_policy.arn

  environment_variables = {
    INSTANCE_ID = "${module.ec2_instance.id}"
  }
  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  tags = {
    Name = "my-lambda1"
    project = "ema2a"
  }
}
module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "ema2a-api-gateway"
  description   = "ema2a api gateway for starting the server"
  protocol_type = "HTTP"


  # Domain Name
  domain_name           = var.domain_name
  create_domain_records = false
  create_certificate    = false
  domain_name_certificate_arn = var.certificate_arn


  # Routes & Integration(s)
  routes = {
    "GET /" = {
      integration = {
        uri = module.lambda_function.lambda_function_arn
        payload_format_version = "2.0"
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "cloudflare_dns_record" "server_dns_record" {
  zone_id = var.cloudflare_zone_id
  name    = var.server_dns_record_name
  type    = "A"
  comment = "Backup Deployments Server Domain verification record"
  content = module.ec2_instance.public_ip
  proxied = true
  ttl     = 1
}
resource "cloudflare_dns_record" "api-gateway_dns_record" {
  zone_id = var.cloudflare_zone_id
  name    = "start"
  type    = "CNAME"
  comment = "Start Server API Gateway Domain verification record"
  content = module.api_gateway.domain_name_target_domain_name
  proxied = false
  ttl     = 3600
}

resource "infisical_identity_aws_auth" "aws-auth" {
  identity_id            = var.infisical_identity_id
  sts_endpoint           = "https://sts.us-east-1.amazonaws.com/"
  allowed_account_ids    = [var.infisical_allowed_account_id]
  allowed_principal_arns = [module.iam_role.arn]
  access_token_ttl       = 2592000
  access_token_max_ttl   = 2592000

  access_token_trusted_ips = [
    { ip_address = "0.0.0.0/0" }
  ]
}
output "cloudflare_target_url" {
  value       = module.api_gateway.domain_name_target_domain_name
  description = "Paste this into Cloudflare as your CNAME target (Grey Cloud!)"
}
# Output the Elastic IP of the server
output "ema2a_server_ip" { 
  value       = module.ec2_instance.public_ip
  description = "The public IP address of the ema2a server"
}


output "iam_role_arn" {
  value       = module.iam_role.arn
  description = "The arn For iam role for Infisical Secrets"
}
