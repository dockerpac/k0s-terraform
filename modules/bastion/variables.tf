variable "cluster_name" {}

variable "vpc_id" {}

variable "instance_profile_name" {}

variable "security_group_id" {}

variable "public_subnet_ids" {
  type = list(string)
}

variable "image_id" {}

variable "kube_cluster_tag" {}

variable "ssh_key" {
  description = "SSH key name"
}

variable "bastion_type" {
  default = "t3.micro"
}

variable "bastion_volume_size" {
  default = 100
}

variable "bastion_count" {
  default = 1
}
