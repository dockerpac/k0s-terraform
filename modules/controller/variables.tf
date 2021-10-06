variable "cluster_name" {}

variable "vpc_id" {}

variable "instance_profile_name" {}

variable "security_group_id" {}

variable "nlb_subnet_ids" {
  type = list(string)
}

variable "instance_subnet_ids" {
  type = list(string)
}

variable "image_id" {}

variable "kube_cluster_tag" {}

variable "ssh_key" {
  description = "SSH key name"
}

variable "controller_count" {
  default = 3
}

variable "controller_type" {
  default = "m5.large"
}

variable "controller_volume_size" {
  default = 100
}
