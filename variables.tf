variable "cluster_name" {
  default = "k0s"
}

# Use local because of terraform workspace
locals {
  cluster_name = "${var.cluster_name}-${terraform.workspace}"
}

variable "k0s_version" {
  default =  "1.22.2+k0s.0"
}

variable "aws_region" {
  default = "eu-west-3"
}

variable "vpc_cidr" {
  default = "172.31.0.0/16"
}

variable "bastion_count" {
  default = 1
}

variable "controller_count" {
  default = 1
}

variable "worker_count" {
  default = 1
}

variable "bastion_type" {
  default = "t3.micro"
}

variable "controller_type" {
  default = "m5.large"
}

variable "worker_type" {
  default = "m5.large"
}

variable "bastion_volume_size" {
  default = 100
}

variable "controller_volume_size" {
  default = 100
}

variable "worker_volume_size" {
  default = 100
}

variable "multi_az" {
  default = "false"
}
