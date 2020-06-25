resource "aws_security_group" "instance" {
  name = var.bastion_name

  description = "SSH traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.bastion_name
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
