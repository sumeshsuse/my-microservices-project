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

  # Kubernetes API server (kubectl / kubeadm join)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # better restrict later
  }

  # NodePort range (if you use NodePort services)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ✅ MUST: allow all node-to-node traffic inside the same SG (CNI needs it)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # ✅ Calico IP-in-IP encapsulation (Protocol 4)
  # (Only needed if Calico uses IPIP; default manifest often does)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "4"
    self      = true
  }

  # ✅ Calico BGP (only if you enabled BGP mode; harmless inside SG)
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

  tags = { Name = "k8s-cluster-sg" }
}

resource "aws_instance" "control_plane" {
  ami                         = var.ami_id
  instance_type               = var.control_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data_control_plane.sh")

  tags = { Name = "k8s-control-plane" }
}

resource "aws_instance" "worker" {
  count                       = var.worker_count
  ami                         = var.ami_id
  instance_type               = var.worker_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  # ✅ IMPORTANT: key name MUST match the placeholder used in user_data_worker.sh
  user_data = templatefile("${path.module}/user_data_worker.sh", {
    CONTROL_PLANE_IP = aws_instance.control_plane.private_ip
  })

  tags = { Name = "k8s-worker-${count.index + 1}" }
}
