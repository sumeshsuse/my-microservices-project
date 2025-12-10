output "harbor_public_ip" {
  description = "Public IP of the Harbor EC2 instance"
  value       = aws_instance.harbor.public_ip
}

output "harbor_url" {
  description = "URL to access Harbor UI"
  value       = "http://${aws_instance.harbor.public_ip}"
}

output "harbor_admin_username" {
  description = "Harbor admin username"
  value       = "admin"
}

output "harbor_admin_password" {
  description = "Harbor admin password (from harbor.yml)"
  value       = "StrongHarborPass123"
  sensitive   = true
}
