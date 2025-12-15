resource "aws_security_group" "harbor_sg" {
  name        = "harbor-sg"
  description = "Allow SSH and HTTP for Harbor (HTTP only)"
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
