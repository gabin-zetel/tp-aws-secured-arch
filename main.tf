terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── Module Bastion ───────────────────────────────────────────────────────────
module "bastion" {
  source = "./modules/vpc_bastion"

  project_name    = var.project_name
  bastion_cidr    = var.bastion_cidr
  subnet_vpn_cidr = var.subnet_vpn_cidr
  subnet_adm_cidr = var.subnet_adm_cidr
  subnet_dmz_cidr = var.subnet_dmz_cidr
  az              = var.availability_zone
  key_name        = var.key_name
  admin_vpn_ip    = var.admin_vpn_ip
  ami_id          = data.aws_ami.ubuntu.id
}

# ─── Modules Clients ──────────────────────────────────────────────────────────
module "client" {
  source   = "./modules/vpc_client"
  for_each = { for c in var.clients : c.name => c }

  project_name     = var.project_name
  client_name      = each.value.name
  client_cidr      = each.value.cidr
  az               = var.availability_zone
  az2              = "us-east-1b"
  key_name         = var.key_name
  ami_id           = data.aws_ami.ubuntu.id
  enable_rds       = each.value.enable_rds
  enable_s3        = each.value.enable_s3
  db_password      = each.value.db_password
  proxy_ip         = module.bastion.proxy_private_ip
  reverse_proxy_ip = module.bastion.reverse_proxy_private_ip
}

# ─── VPC Peering Bastion ↔ Clients ───────────────────────────────────────────
resource "aws_vpc_peering_connection" "bastion_to_client" {
  for_each = module.client

  vpc_id      = module.bastion.vpc_id
  peer_vpc_id = each.value.vpc_id
  auto_accept = true

  tags = {
    Name    = "${var.project_name}-peering-bastion-${each.key}"
    Project = var.project_name
  }
}

# Route Bastion DMZ → Client
resource "aws_route" "bastion_to_client" {
  for_each = module.client

  route_table_id            = module.bastion.dmz_route_table_id
  destination_cidr_block    = each.value.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_client[each.key].id
}

# Route Client → Bastion DMZ (pour sortir via proxy)
resource "aws_route" "client_to_bastion" {
  for_each = module.client

  route_table_id            = each.value.route_table_id
  destination_cidr_block    = var.subnet_dmz_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_client[each.key].id
}
