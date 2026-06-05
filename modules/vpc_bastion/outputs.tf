output "vpc_id"                   { value = aws_vpc.bastion.id }
output "dmz_route_table_id"       { value = aws_route_table.public.id }
output "proxy_private_ip"         { value = aws_instance.proxy.private_ip }
output "reverse_proxy_private_ip" { value = aws_instance.reverse_proxy.private_ip }
output "reverse_proxy_public_ip"  { value = aws_eip.reverse_proxy.public_ip }
output "vpn_public_ip"            { value = aws_instance.vpn.public_ip }
