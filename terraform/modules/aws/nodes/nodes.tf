data "aws_kms_key" "kms" {
  key_id = var.kms_key
}

resource "aws_lb_target_group_attachment" "nodes" {
  count = var.cluster_size

  target_group_arn = var.aws_lb_target_group_vault_health
  target_id        = aws_instance.nodes[count.index].id
  port             = 8200
}

resource "aws_instance" "nodes" {
  count = var.cluster_size

  ami                         = var.ami_id
  availability_zone           = var.aws_availability_zones[count.index]
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[count.index]
  vpc_security_group_ids      = [aws_security_group.nodes.id]
  associate_public_ip_address = false
  iam_instance_profile        = var.iam_instance_profile

  user_data = element(data.ignition_config.nodes.*.rendered, count.index)

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = var.root_volume_delete_on_termination
  }

  tags = {
    Name    = "vault-${var.aws_availability_zones[count.index]}-${count.index}.${var.cluster_name}"
    Cluster = var.cluster_name
    NodeID  = "vault-${var.aws_availability_zones[count.index]}-${count.index}"
  }
}

resource "aws_ebs_volume" "volumes" {
  count = var.cluster_size

  encrypted         = true
  availability_zone = var.aws_availability_zones[count.index]
  size              = 100
  kms_key_id        = data.aws_kms_key.kms.arn

  tags = {
    Name    = "vault-${var.aws_availability_zones[count.index]}-${count.index}.${var.cluster_name}"
    Cluster = var.cluster_name
    NodeID  = "vault-${var.aws_availability_zones[count.index]}-${count.index}"
  }
}

resource "aws_volume_attachment" "volumes_attach" {
  count = var.cluster_size

  device_name = "/dev/xvdh"

  volume_id   = aws_ebs_volume.volumes[count.index].id
  instance_id = aws_instance.nodes[count.index].id
}
