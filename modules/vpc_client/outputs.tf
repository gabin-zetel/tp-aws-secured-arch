output "vpc_id"                { value = aws_vpc.client.id }
output "vpc_cidr"              { value = aws_vpc.client.cidr_block }
output "route_table_id"        { value = aws_route_table.client.id }
output "web_server_private_ip" { value = aws_instance.web.private_ip }
output "rds_endpoint"          { value = var.enable_rds ? aws_db_instance.client[0].endpoint : null }
output "s3_bucket_name"        { value = var.enable_s3 ? aws_s3_bucket.client[0].bucket : null }
