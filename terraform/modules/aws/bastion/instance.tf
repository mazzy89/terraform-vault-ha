resource "aws_eip" "eip" {
  instance = aws_instance.instance.id
  vpc      = true
}

resource "aws_instance" "instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.instance.id]
  associate_public_ip_address = true

  user_data = data.ignition_config.instance.rendered

  tags = {
    Name = var.bastion_name
  }

  # Ignore changes in the AMI which force recreation of the resource. This
  # avoids accidental deletion of nodes whenever a new Flatcar Release comes
  # out.
  lifecycle {
    ignore_changes = [ami]
  }
}
