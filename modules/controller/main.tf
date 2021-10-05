resource "aws_security_group" "controller" {
  name        = "${var.cluster_name}-controllers"
  description = "k0s cluster controllers"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [
      description
    ]
  }
}

locals {
  subnet_count = "${length(var.subnet_ids)}"
}


resource "aws_instance" "k0s_controller" {
  count = var.controller_count

  tags = {
    Name = "${var.cluster_name}-controller-${count.index + 1}",
    Role = "controller",
    "${var.kube_cluster_tag}" = "shared"
  } 

  instance_type          = var.controller_type
  iam_instance_profile   = var.instance_profile_name
  ami                    = var.image_id
  key_name               = var.ssh_key
  vpc_security_group_ids = [var.security_group_id, aws_security_group.controller.id]
  subnet_id              = var.subnet_ids[count.index % local.subnet_count]
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
    volume_size = var.controller_volume_size
  }
}

resource "aws_lb" "k0s_controller" {
  name               = "${var.cluster_name}-controller-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  tags = {
    Cluster = var.cluster_name
  }
}

resource "aws_lb_target_group" "k0s_kube_api" {
  name     = "${var.cluster_name}-kube-api"
  port     = 6443
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "k0s_kube_api" {
  load_balancer_arn = aws_lb.k0s_controller.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.k0s_kube_api.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "k0s_kube_api" {
  count            = var.controller_count
  target_group_arn = aws_lb_target_group.k0s_kube_api.arn
  target_id        = aws_instance.k0s_controller[count.index].id
  port             = 6443
}
