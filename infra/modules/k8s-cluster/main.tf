resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-sg"
  description = "Security group for Kubernetes cluster"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Kubernetes API server (kubectl / worker join)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # better: restrict to your IP
  }

  # NodePort range (apps)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ✅ MOST IMPORTANT: allow ALL intra-cluster traffic within same SG (node<->node, pod overlay)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # ✅ Calico IP-in-IP encapsulation (Protocol 4) — you have CALICO_IPV4POOL_IPIP=Always
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "4"
    self      = true
  }

  # ✅ Calico BGP (TCP 179) — your calico shows CLUSTER_TYPE: k8s,bgp
  ingress {
    from_port = 179
    to_port   = 179
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-cluster-sg"
  }
}

resource "aws_instance" "control_plane" {
  ami                         = var.ami_id
  instance_type               = var.control_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data_control_plane.sh")

  tags = {
    Name = "k8s-control-plane"
  }
}

resource "aws_instance" "worker" {
  count                       = var.worker_count
  ami                         = var.ami_id
  instance_type               = var.worker_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  # ✅ IMPORTANT: pass control-plane private IP into worker script
  user_data = templatefile("${path.module}/user_data_worker.sh", {
    CONTROL_PLANE_PRIVATE_IP = aws_instance.control_plane.private_ip
  })

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}
