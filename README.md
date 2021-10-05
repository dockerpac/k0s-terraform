# Bootstrapping K0S cluster on AWS

This directory provides an example flow for using k0sctl with Terraform and AWS.

## Prerequisites

* An account and credentials for AWS.
* k0sctl [installed](https://github.com/k0sproject/k0sctl/releases)
* Terraform [installed](https://learn.hashicorp.com/terraform/getting-started/install)

## Steps

1. Create terraform.tfvars file with needed details. You can use the provided terraform.tfvars.example as a baseline.
2. `terraform init`
3. (optional Create a Terraform Workspace). `terraform workspace new cluster1`
4. `terraform apply`
5. `terraform output -raw k0s_cluster | k0sctl apply --config -`
6. Get kubeconfig (with trick to use LB dns name instead of controller IP). `terraform output -raw k0s_cluster | k0sctl kubeconfig --config - | sed "s/server:.*/server: https\:\/\/$(terraform output -raw lb_dns_name)\:6443/" > kubeconfig-$(terraform workspace show)`
7. Test your cluster. `KUBECONFIG=$(pwd)/kubeconfig-$(terraform workspace show) kubectl get nodes`
