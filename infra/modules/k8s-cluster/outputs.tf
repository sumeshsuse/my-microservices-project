output "control_plane_public_ip" {
  description = "Public IP of the control plane"
  value       = aws_instance.control_plane.public_ip
}

output "worker_public_ips" {
  description = "Public IPs of worker nodes"
  value       = [for w in aws_instance.worker : w.public_ip]
}

