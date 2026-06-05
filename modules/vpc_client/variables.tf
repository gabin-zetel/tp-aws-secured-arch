variable "project_name"     { type = string }
variable "client_name"      { type = string }
variable "client_cidr"      { type = string }
variable "az"               { type = string }
variable "az2" {
  type    = string
  default = "us-east-1b"
}
variable "key_name"         { type = string }
variable "ami_id"           { type = string }
variable "enable_rds" {
  type    = bool
  default = false
}
variable "enable_s3" {
  type    = bool
  default = false
}
variable "db_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "proxy_ip"         { type = string }
variable "reverse_proxy_ip" { type = string }
