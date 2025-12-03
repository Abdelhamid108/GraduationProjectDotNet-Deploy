########################################
# VPC
########################################
resource "aws_vpc" "k8s_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "k8s-vpc"
  }
}

########################################
# Internet Gateway (for Public Subnet)
########################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "k8s-igw"
  }
}

########################################
# Public Subnet for k8s masters
########################################
resource "aws_subnet" "k8s_public_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = var.k8s_public_subnet_cidr1
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name                                   = "k8s-public-subnet-1"
    "kubernetes.io/cluster/kubernetes"     = "shared"
    "kubernetes.io/role/elb"               = "1"
  }
}

########################################
# Jenkins Public Subnet 
########################################
resource "aws_subnet" "jenkins_public_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = var.jenkins_public_subnet_cidr2
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name                                   = "jenkins-public-subnet-2"
    "kubernetes.io/cluster/kubernetes"     = "shared"
    "kubernetes.io/role/elb"               = "1"
  }
}

########################################
# Private Subnet for k8s workers
########################################
resource "aws_subnet" "k8s_private_app_subnet1" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = var.k8s_private_app_subnet_cidr1
  availability_zone = "${var.aws_region}b"

  tags = {
    Name                                   = "k8s-private-app-subnet1"
    "kubernetes.io/cluster/kubernetes"     = "shared"
    "kubernetes.io/role/internal-elb"      = "1"
  }
}

########################################
# Private Subnet for k8s workers
########################################
resource "aws_subnet" "k8s_private_app_subnet2" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = var.k8s_private_app_subnet_cidr2
  availability_zone = "${var.aws_region}a"

  tags = {
    Name                                   = "k8s-private-app-subnet2"
    "kubernetes.io/cluster/kubernetes"     = "shared"
    "kubernetes.io/role/internal-elb"      = "1"
  }
}

########################################
# Public Route Table (Internet access)
########################################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "k8s-public-rt"
  }
}

# Associate Public Subnet to Public RT
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.k8s_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
# Associate Public Subnet 2 with Public Route Table
resource "aws_route_table_association" "public_assoc2" {
  subnet_id      = aws_subnet.jenkins_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


########################################
# NAT Gateway (for private subnets)
########################################
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "k8s-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.k8s_public_subnet.id

  tags = {
    Name = "k8s-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

########################################
# Private Route Table (uses NAT)
########################################
resource "aws_route_table" "private_app_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "k8s-private-app-rt"
  }
}

# Associate private subnets
resource "aws_route_table_association" "private_app_assoc1" {
  subnet_id      = aws_subnet.k8s_private_app_subnet1.id
  route_table_id = aws_route_table.private_app_rt.id
}

resource "aws_route_table_association" "private_app_assoc2" {
  subnet_id      = aws_subnet.k8s_private_app_subnet2.id
  route_table_id = aws_route_table.private_app_rt.id
}

