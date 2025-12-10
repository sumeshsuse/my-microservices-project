output "harbor_public_ip" {
  description = "Public IP of the Harbor EC2 instance"
  value       = module.harbor.harbor_public_ip
}

output "harbor_url" {
  description = "URL to access Harbor UI"
  value       = module.harbor.harbor_url
}

output "harbor_admin_username" {
  description = "Harbor admin username"
  value       = module.harbor.harbor_admin_username
}

output "harbor_admin_password" {
  description = "Harbor admin password"
  value       = module.harbor.harbor_admin_password
  sensitive   = true
}

output "control_plane_public_ip" {
  description = "Public IP of the control plane"
  value       = module.k8s_cluster.control_plane_public_ip
}

output "worker_public_ips" {
  description = "Public IPs of worker nodes"
  value       = module.k8s_cluster.worker_public_ips
}

