# ─── VPC ─────────────────────────────────────────────────────────────────────
resource "aws_vpc" "bastion" {
  cidr_block           = var.bastion_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.project_name}-vpc-bastion", Project = var.project_name }
}

resource "aws_internet_gateway" "bastion" {
  vpc_id = aws_vpc.bastion.id
  tags   = { Name = "${var.project_name}-igw", Project = var.project_name }
}

# ─── Subnets ──────────────────────────────────────────────────────────────────
resource "aws_subnet" "vpn" {
  vpc_id                  = aws_vpc.bastion.id
  cidr_block              = var.subnet_vpn_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-subnet-vpn", Project = var.project_name }
}

resource "aws_subnet" "admin" {
  vpc_id                  = aws_vpc.bastion.id
  cidr_block              = var.subnet_adm_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = false
  tags = { Name = "${var.project_name}-subnet-admin", Project = var.project_name }
}

resource "aws_subnet" "dmz" {
  vpc_id                  = aws_vpc.bastion.id
  cidr_block              = var.subnet_dmz_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-subnet-dmz", Project = var.project_name }
}

# ─── Route Tables ─────────────────────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.bastion.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bastion.id
  }
  tags = { Name = "${var.project_name}-rt-public", Project = var.project_name }
}

resource "aws_route_table" "admin" {
  vpc_id = aws_vpc.bastion.id
  tags   = { Name = "${var.project_name}-rt-admin", Project = var.project_name }
}

resource "aws_route_table_association" "vpn" {
  subnet_id      = aws_subnet.vpn.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "dmz" {
  subnet_id      = aws_subnet.dmz.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "admin" {
  subnet_id      = aws_subnet.admin.id
  route_table_id = aws_route_table.admin.id
}

# ─── Security Groups ──────────────────────────────────────────────────────────
resource "aws_security_group" "vpn" {
  name        = "${var.project_name}-sg-vpn"
  description = "Acces VPN depuis IP admin uniquement"
  vpc_id      = aws_vpc.bastion.id

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = [var.admin_vpn_ip]
    description = "OpenVPN"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_vpn_ip]
    description = "SSH bootstrap"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-sg-vpn", Project = var.project_name }
}

resource "aws_security_group" "admin" {
  name        = "${var.project_name}-sg-admin"
  description = "SSH uniquement depuis subnet VPN"
  vpc_id      = aws_vpc.bastion.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.subnet_vpn_cidr]
    description = "SSH via tunnel VPN"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-sg-admin", Project = var.project_name }
}

resource "aws_security_group" "proxy" {
  name        = "${var.project_name}-sg-proxy"
  description = "Squid proxy - acces depuis VPCs clients uniquement"
  vpc_id      = aws_vpc.bastion.id

  ingress {
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Proxy depuis clients"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.subnet_adm_cidr]
    description = "SSH depuis admin"
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-sg-proxy", Project = var.project_name }
}

resource "aws_security_group" "reverse_proxy" {
  name        = "${var.project_name}-sg-rproxy"
  description = "Nginx reverse proxy - HTTP/S public"
  vpc_id      = aws_vpc.bastion.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP public"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS public"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.subnet_adm_cidr]
    description = "SSH depuis admin"
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Forward vers web clients"
  }
  tags = { Name = "${var.project_name}-sg-rproxy", Project = var.project_name }
}

# ─── Instances ────────────────────────────────────────────────────────────────
resource "aws_instance" "vpn" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.vpn.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.vpn.id]
  source_dest_check      = false

  user_data = base64encode(templatefile("${path.module}/../../user_data/vpn.sh", {
    vpn_subnet = "10.8.0.0"
    vpn_mask   = "255.255.255.0"
  }))

  tags = { Name = "${var.project_name}-vpn", Project = var.project_name, Role = "vpn" }
}

resource "aws_instance" "admin" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.admin.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.admin.id]
  user_data              = base64encode(file("${path.module}/../../user_data/admin.sh"))

  tags = { Name = "${var.project_name}-admin", Project = var.project_name, Role = "admin" }
}

resource "aws_instance" "proxy" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.dmz.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.proxy.id]
  user_data              = base64encode(file("${path.module}/../../user_data/proxy.sh"))

  tags = { Name = "${var.project_name}-proxy", Project = var.project_name, Role = "proxy" }
}

resource "aws_eip" "reverse_proxy" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-eip-rproxy", Project = var.project_name }
}

resource "aws_instance" "reverse_proxy" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.dmz.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.reverse_proxy.id]
  user_data              = base64encode(file("${path.module}/../../user_data/reverse_proxy.sh"))

  tags = { Name = "${var.project_name}-rproxy", Project = var.project_name, Role = "reverse-proxy" }
}

resource "aws_eip_association" "reverse_proxy" {
  instance_id   = aws_instance.reverse_proxy.id
  allocation_id = aws_eip.reverse_proxy.id
}
