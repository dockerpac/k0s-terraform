variable "cluster_name" {}

variable "host_cidr" {
  description = "CIDR IPv4 range to assign to EC2 nodes"
  default     = "172.31.0.0/16"
}

variable "multi_az" {
  default = "false"
}

variable "private_network" {
  default = "false"
}