packer {

  required_plugins {

    amazon = {

      version = ">= 1.2.8"

      source  = "github.com/hashicorp/amazon"

    }
    
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }


  }

}

variable "ami-prefix" {
  type    = string
  default = "ema2a-backup-deployment-instance" 
}

variable "instance-type" {
  type     = string
  default  = "c7i-flex.large"
}

variable "region" {
  type     = string
  default  = "us-east-1"
}

variable "ssh-user" {
  type     = string
  default  = "ec2-user"
 
}

variable "base-ami" {
  type     = string
  default  = "al2023-ami-2023.*-x86_64"
}

source "amazon-ebs" "ema2a" {

  ami_name      = "${var.ami-prefix}-{{timestamp}}"
  

  instance_type = var.instance-type

  region        = var.region

  tags = {
    Project   = "ema2a"
    Component = "server-ami" 
  }
  source_ami_filter {

    filters = {

      name                = var.base-ami

      root-device-type    = "ebs"

      virtualization-type = "hvm"

    }

    most_recent = true

    owners      = ["137112412989"]

  }

  ssh_username = var.ssh-user

}



build {

  name    = "learn-packer"

  sources = [

    "source.amazon-ebs.ema2a"

  ]
  
  provisioner "shell" {
  inline = [
    "echo 'Checking if cloud-init has finished...'",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 2; done",
      "echo 'Cloud-init finished! Proceeding with Ansible.'"
   ]
  }
  
  provisioner "ansible" {
   playbook_file = "./Ansible/site.yml"
   user          = var.ssh-user
  
    # Extra SSH arguments required to make Packer and Ansible play nicely together
    # using Packer's automatically generated temporary SSH keys.
    extra_arguments = [
      "--scp-extra-args", "'-O'",
      "--ssh-extra-args", "-o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa"
    ]

  }
  
  provisioner "shell" {
  inline = [
      "echo 'Cleaning the AMI to save space...'",
      "sudo yum clean all",
      "sudo rm -rf /var/cache/yum"
   ]
  }
  
}

