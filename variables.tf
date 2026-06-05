variable "project_name" {
  type    = string
  default = "secured-arch"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "key_name" {
  type = string
}

variable "admin_vpn_ip" {
  type = string
}

variable "bastion_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_vpn_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_adm_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "subnet_dmz_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "clients" {
  type = list(object({
    name        = string
    cidr        = string
    enable_rds  = bool
    enable_s3   = bool
    db_password = string
  }))
}
