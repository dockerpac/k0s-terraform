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
6. `terraform output -raw k0s_cluster | k0sctl kubeconfig --config - > kubeconfig-$(terraform workspace show)`
7. Test your cluster. `KUBECONFIG=$(pwd)/kubeconfig-$(terraform workspace show) kubectl get nodes`


## TODO : cloud provider
1. Label each controller node `kubectl label node <controller> node-role.kubernetes.io/master=`
2. Taint controller nodes `kubectl taint nodes -l node-role.kubernetes.io/master= node-role.kubernetes.io/master:NoSchedule`
2. Deploy CloudControllerManager. `kubectl apply -f ccm.yaml`

# Check Ingress
1. `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.3/deploy/static/provider/aws/deploy.yaml`
2. `export EXTERNAL_DNS=$(kubectl get services --namespace ingress-nginx ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')`
3. `envsubst < dockerdemo.yaml | kubectl apply -f -`
4. `curl -k https://${EXTERNAL_DNS}`

# Tear down
1. `kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.3/deploy/static/provider/aws/deploy.yaml`
2. `terraform destroy`
