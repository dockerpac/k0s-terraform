locals {
  public_subnet_count = "${length(var.public_subnet_ids)}"
}

resource "aws_security_group" "bastion" {
  name        = "${var.cluster_name}-bastion"
  description = "k0s cluster bastion"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "k0s_bastion" {
  count = var.bastion_count

  tags = {
    Name = "${var.cluster_name}-bastion-${count.index + 1}",
    Role = "bastion",
    "${var.kube_cluster_tag}" = "shared"
  } 

  instance_type          = var.bastion_type
  iam_instance_profile   = var.instance_profile_name
  ami                    = var.image_id
  key_name               = var.ssh_key
  vpc_security_group_ids = [var.security_group_id, aws_security_group.bastion.id]
  subnet_id              = var.public_subnet_ids[count.index % local.public_subnet_count]
  ebs_optimized          = true
  user_data              = <<EOF
#!/bin/bash
# Use full qualified private DNS name for the host name.  Kube wants it this way.
HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/hostname)
echo $HOSTNAME > /etc/hostname
sed -i "s|\(127\.0\..\.. *\)localhost|\1$HOSTNAME|" /etc/hosts
hostname $HOSTNAME
EOF

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = var.bastion_volume_size
  }
}
