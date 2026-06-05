output "vpn_public_ip" {
  description = "IP publique du serveur VPN — point d'entrée admin"
  value       = module.bastion.vpn_public_ip
}

output "reverse_proxy_public_ip" {
  description = "IP publique du Reverse Proxy — point d'entrée HTTP/S"
  value       = module.bastion.reverse_proxy_public_ip
}

output "client_web_private_ips" {
  description = "IPs privées des serveurs web clients"
  value       = { for k, v in module.client : k => v.web_server_private_ip }
}

output "client_rds_endpoints" {
  description = "Endpoints RDS par client"
  value       = { for k, v in module.client : k => v.rds_endpoint if v.rds_endpoint != null }
}

output "client_s3_buckets" {
  description = "Noms des buckets S3 par client"
  value       = { for k, v in module.client : k => v.s3_bucket_name if v.s3_bucket_name != null }
}
