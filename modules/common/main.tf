
data "aws_availability_zones" "available" {}

resource "tls_private_key" "ssh_key" {
  algorithm   = "RSA"
  rsa_bits = "4096"
}

resource "local_file" "ssh_public_key" {
  content     = tls_private_key.ssh_key.private_key_pem
  filename    = "ssh_keys/${var.cluster_name}.pem"
  provisioner "local-exec" {
    command = "chmod 0600 ${local_file.ssh_public_key.filename}"
  }
}

resource "aws_key_pair" "key" {
  key_name   = var.cluster_name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "common" {
  name        = "${var.cluster_name}-common"
  description = "k0s cluster common rules"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  } 
}

resource "aws_iam_role" "role" {
  name = "${var.cluster_name}_host"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.cluster_name}_host"
  role = aws_iam_role.role.name
}

resource "aws_iam_role_policy" "policy" {
  name = "${var.cluster_name}_host"
  role = aws_iam_role.role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["elasticloadbalancing:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["ecr:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*"
    },
    {
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": "arn:aws:s3:::${var.cluster_name}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": "arn:aws:s3:::${var.cluster_name}/*"
        }
  ]
}
EOF
}
