resource "aws_vpc" "client" {
  cidr_block           = var.client_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.project_name}-vpc-${var.client_name}", Project = var.project_name, Client = var.client_name }
}

resource "aws_subnet" "web" {
  vpc_id            = aws_vpc.client.id
  cidr_block        = cidrsubnet(var.client_cidr, 8, 1)
  availability_zone = var.az
  tags = { Name = "${var.project_name}-${var.client_name}-subnet-web", Project = var.project_name }
}

resource "aws_subnet" "db" {
  count             = var.enable_rds ? 1 : 0
  vpc_id            = aws_vpc.client.id
  cidr_block        = cidrsubnet(var.client_cidr, 8, 2)
  availability_zone = var.az
  tags = { Name = "${var.project_name}-${var.client_name}-subnet-db", Project = var.project_name }
}

resource "aws_subnet" "db2" {
  count             = var.enable_rds ? 1 : 0
  vpc_id            = aws_vpc.client.id
  cidr_block        = cidrsubnet(var.client_cidr, 8, 3)
  availability_zone = var.az2
  tags = { Name = "${var.project_name}-${var.client_name}-subnet-db2", Project = var.project_name }
}

resource "aws_route_table" "client" {
  vpc_id = aws_vpc.client.id
  tags   = { Name = "${var.project_name}-${var.client_name}-rt", Project = var.project_name }
}

resource "aws_route_table_association" "web" {
  subnet_id      = aws_subnet.web.id
  route_table_id = aws_route_table.client.id
}

# ─── Security Groups ──────────────────────────────────────────────────────────
resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.client_name}-sg-web"
  description = "HTTP depuis Reverse Proxy uniquement"
  vpc_id      = aws_vpc.client.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.reverse_proxy_ip}/32"]
    description = "HTTP depuis Reverse Proxy"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
    description = "SSH depuis admin bastion"
  }
  egress {
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = ["${var.proxy_ip}/32"]
    description = "Sortie via proxy Squid"
  }
  tags = { Name = "${var.project_name}-${var.client_name}-sg-web", Project = var.project_name }
}

resource "aws_security_group" "rds" {
  count       = var.enable_rds ? 1 : 0
  name        = "${var.project_name}-${var.client_name}-sg-rds"
  description = "MySQL depuis serveur web uniquement"
  vpc_id      = aws_vpc.client.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
    description     = "MySQL depuis web"
  }
  tags = { Name = "${var.project_name}-${var.client_name}-sg-rds", Project = var.project_name }
}

# ─── Instance Web ─────────────────────────────────────────────────────────────
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.web.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/../../user_data/web.sh", {
    client_name = var.client_name
    proxy_ip    = var.proxy_ip
  }))

  tags = { Name = "${var.project_name}-${var.client_name}-web", Project = var.project_name, Client = var.client_name }
}

# ─── RDS ──────────────────────────────────────────────────────────────────────
resource "aws_db_subnet_group" "client" {
  count      = var.enable_rds ? 1 : 0
  name       = "${var.project_name}-${var.client_name}-dbsg"
  subnet_ids = [aws_subnet.db[0].id, aws_subnet.db2[0].id]
  tags       = { Name = "${var.project_name}-${var.client_name}-dbsg", Project = var.project_name }
}

resource "aws_db_instance" "client" {
  count                  = var.enable_rds ? 1 : 0
  identifier             = "${var.project_name}-${var.client_name}-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = replace(var.client_name, "-", "")
  username               = "admin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.client[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  skip_final_snapshot    = true
  storage_encrypted      = true
  tags                   = { Name = "${var.project_name}-${var.client_name}-rds", Project = var.project_name, Client = var.client_name }
}

# ─── S3 ───────────────────────────────────────────────────────────────────────
resource "random_id" "suffix" {
  count       = var.enable_s3 ? 1 : 0
  byte_length = 4
}

resource "aws_s3_bucket" "client" {
  count  = var.enable_s3 ? 1 : 0
  bucket = "${var.project_name}-${var.client_name}-${random_id.suffix[0].hex}"
  tags   = { Name = "${var.project_name}-${var.client_name}-s3", Project = var.project_name, Client = var.client_name }
}

resource "aws_s3_bucket_versioning" "client" {
  count  = var.enable_s3 ? 1 : 0
  bucket = aws_s3_bucket.client[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "client" {
  count  = var.enable_s3 ? 1 : 0
  bucket = aws_s3_bucket.client[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "client" {
  count                   = var.enable_s3 ? 1 : 0
  bucket                  = aws_s3_bucket.client[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
