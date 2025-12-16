resource "aws_security_group" "harbor_sg" {
  name        = "harbor-sg"
  description = "Allow SSH and HTTP for Harbor (HTTP only) + allow 443 probe from client CIDR"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP Harbor UI & Registry"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # IMPORTANT: Docker tries HTTPS first. AWS SG drops packets if port not allowed → timeout.
  # We allow 443 ONLY from your client CIDR, then we will "reject" 443 on the instance (ufw)
  # so Docker fails fast and falls back to HTTP.
  ingress {
    description = "HTTPS probe for Docker (allow from client CIDR only)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "harbor-sg"
  }
}

resource "aws_instance" "harbor" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.harbor_sg.id]

  associate_public_ip_address = true

  user_data = file("${path.module}/user_data_harbor.sh")

  tags = {
    Name = "harbor-ec2"
  }
}
