provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source       = "./modules/vpc"
  cluster_name = local.cluster_name
  host_cidr    = var.vpc_cidr
  multi_az     = var.multi_az
}

module "common" {
  source       = "./modules/common"
  cluster_name = local.cluster_name
  vpc_id       = module.vpc.id
}

module "bastion" {
  source                = "./modules/bastion"
  bastion_count         = var.bastion_count
  vpc_id                = module.vpc.id
  cluster_name          = local.cluster_name
  public_subnet_ids     = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  image_id              = module.common.image_id
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = local.cluster_name
  instance_profile_name = module.common.instance_profile_name
  bastion_type          = var.bastion_type
}

module "controllers" {
  source                = "./modules/controller"
  controller_count      = var.controller_count
  vpc_id                = module.vpc.id
  cluster_name          = local.cluster_name
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_id     = module.common.security_group_id
  image_id              = module.common.image_id
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = local.cluster_name
  instance_profile_name = module.common.instance_profile_name
  controller_type       = var.controller_type
}


module "workers" {
  source                = "./modules/worker"
  worker_count          = var.worker_count
  vpc_id                = module.vpc.id
  cluster_name          = local.cluster_name
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_id     = module.common.security_group_id
  image_id              = module.common.image_id
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = local.cluster_name
  instance_profile_name = module.common.instance_profile_name
  worker_type           = var.worker_type
}

locals {
  controllers = [
    for host in module.controllers.machines : {
      ssh = {
        address = host.private_ip
        user    = "ubuntu"
        bastion = { 
          address = module.bastion.public_ips[0] # Use 1st bastion
          user    = "ubuntu"
          keyPath = "./ssh_keys/${local.cluster_name}.pem"
        }
      }
      #role = "controller+worker"
      role = "controller"
    }
  ]
  workers = [
    for host in module.workers.machines : {
      ssh = {
        address = host.private_ip
        user    = "ubuntu"
        bastion = { 
          address = module.bastion.public_ips[0] # Use 1st bastion
          user    = "ubuntu"
          keyPath = "./ssh_keys/${local.cluster_name}.pem"
        }
      }
      role  = "worker"
    }
  ]
  launchpad_tmpl = {
    apiVersion = "k0sctl.k0sproject.io/v1beta1"
    kind       = "Cluster"
    metadata = {
      name = "${local.cluster_name}"
    }
    spec = {
      k0s = {
        version =  "${var.k0s_version}"
        config = {
          spec = {
            api = {
              externalAddress = "${module.controllers.lb_dns_name}"
              sans = [
                "${module.controllers.lb_dns_name}"
              ]
            }
            network = {
              provider = "calico"
            }
          }
        }
      }
      hosts = concat(local.controllers, local.workers)
    }
  }
}

output "k0s_cluster" {
  value = yamlencode(local.launchpad_tmpl)
}

output "lb_dns_name" {
  value = "${module.controllers.lb_dns_name}"
}