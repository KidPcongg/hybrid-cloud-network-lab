resource "aws_vpc" "hcn" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = false
  instance_tenancy     = "default"

  tags = {
    Project = "hybrid-cloud-network-lab"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.hcn.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "hcn-public-a"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.hcn.id
  cidr_block              = "10.10.10.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "hcn-private-a"
  }
}

resource "aws_internet_gateway" "hcn" {
  vpc_id = aws_vpc.hcn.id

  tags = {
    Name    = "hcn-igw"
    Project = "hybrid-cloud-network-lab"
  }
}

resource "aws_security_group" "vpn" {
  name        = "hcn-vpn-sg"
  description = "Security group for HCN Lab WireGuard gateway"
  vpc_id      = aws_vpc.hcn.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "hybrid-cloud-network-lab"
  }
}

resource "aws_security_group" "private_app" {
  name        = "hcn-private-app-sg"
  description = "Allow lab application access from on-prem LAN"
  vpc_id      = aws_vpc.hcn.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.1.130/32"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["172.16.10.0/24"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["172.16.10.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "HCN"
  }
}

resource "aws_instance" "vpn_gateway" {
  ami                         = "ami-03acbba64aef9bf5c"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  private_ip                  = "10.10.1.130"
  key_name                    = "hcn-lab-key"
  vpc_security_group_ids      = [aws_security_group.vpn.id]
  associate_public_ip_address = true
  source_dest_check           = false

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    iops                  = 3000
    throughput            = 125
    volume_size           = 8
    volume_type           = "gp3"
  }

  tags = {
    Name    = "hcn-vpn-gw"
    Project = "HCN"
  }
}

resource "aws_instance" "private_app" {
  ami                         = "ami-03acbba64aef9bf5c"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private.id
  private_ip                  = "10.10.10.7"
  key_name                    = "hcn-lab-key"
  vpc_security_group_ids      = [aws_security_group.private_app.id]
  associate_public_ip_address = false
  source_dest_check           = true

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    iops                  = 3000
    throughput            = 125
    volume_size           = 8
    volume_type           = "gp3"
  }

  tags = {
    Name    = "hcn-private-app"
    Project = "HCN"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.hcn.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hcn.id
  }

  tags = {
    Name    = "hcn-public-rt"
    Project = "hybrid-cloud-network-lab"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.hcn.id

  route {
    cidr_block           = "172.16.10.0/24"
    network_interface_id = aws_instance.vpn_gateway.primary_network_interface_id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
