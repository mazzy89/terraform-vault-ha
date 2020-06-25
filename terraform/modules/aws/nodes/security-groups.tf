resource "aws_security_group" "nodes" {
  name        = var.cluster_name
  description = "SSH and Internal Vault Traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name    = var.cluster_name
    Cluster = var.cluster_name
  }

  # SSH
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
  }

  # Vault API traffic
  ingress {
    from_port       = 8200
    to_port         = 8200
    protocol        = "tcp"
    security_groups = [var.aws_lb_security_group_id]
  }

  # Vault cluster traffic
  ingress {
    from_port       = 8201
    to_port         = 8201
    protocol        = "tcp"
    security_groups = [var.aws_lb_security_group_id]
  }

  # Internal Traffic
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # TODO(mazzy89): add rule for node-exporter

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
