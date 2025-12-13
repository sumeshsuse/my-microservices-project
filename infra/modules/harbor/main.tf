resource "aws_security_group" "harbor_sg" {
  name        = "harbor-sg"
  description = "Allow SSH and HTTP/HTTPS for Harbor"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # HTTP (Harbor UI + registry redirect/help)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (Harbor UI + Docker registry login/push/pull)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress: allow all
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

  # Use our user_data script file
  user_data = file("${path.module}/user_data_harbor.sh")

  tags = {
    Name = "harbor-ec2"
  }
}
