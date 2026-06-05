# Projet AWS — Secured Architecture

## Groupe
- Gabin MENDY
- Evan NOIROT
- Edmond Tresor NGOMBE MATANDA

## Description
Infrastructure AWS multi-VPC sécurisée déployée avec Terraform (IaC).

## Architecture
- **VPC Bastion** (10.0.0.0/16) : VPN OpenVPN, Poste Admin, Proxy Squid, Reverse Proxy Nginx
- **VPC Client A** (10.1.0.0/16) : Web Nginx + RDS MySQL + S3
- **VPC Client B** (10.2.0.0/16) : Web Nginx + RDS MySQL + S3
- VPC Peering Bastion ↔ Clients (aucun peering inter-clients)
- Région : us-east-1 (Virginie du Nord)

## Déploiement
```bash
cp terraform.tfvars.example terraform.tfvars
# Renseigner key_name et admin_vpn_ip
terraform init && terraform apply
```

## Ajouter un client en < 3 minutes
```bash
./deploy_client.sh client-c 10.3.0.0/16 --rds --s3
```

## Validation de conformité
```bash
python3 compliance_check.py --region us-east-1 --project secured-arch
```
