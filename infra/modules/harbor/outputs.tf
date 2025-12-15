output "harbor_public_ip" {
  description = "Public IP of Harbor EC2"
  value       = aws_instance.harbor.public_ip
}

output "harbor_url" {
  description = "Harbor UI URL (HTTP)"
  value       = "http://${aws_instance.harbor.public_ip}"
}

output "harbor_admin_username" {
  value = "admin"
}

output "harbor_admin_password" {
  value     = "StrongHarborPass123"
  sensitive = true
}
