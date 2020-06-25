# Vault HA - BETA

Run Hashicorp Vault in High Availability with storage backend [Raft](https://www.vaultproject.io/docs/configuration/storage/raft).

## Technologies

- Terraform 0.12
- Flatcar Linux OS with Ignition v2
- Hashicorp Vault
- [bank-vaults](https://github.com/banzaicloud/bank-vaults/tree/master/cmd/bank-vaults)
- Monitoring: [Node Exporter](https://github.com/prometheus/node_exporter)

## Features

A list of features (some provider-specific)

- Storage backend: Raft
- Vault Auto-Unseal with AWS KMS (only on AWS)
- Store recovery keys in encrypted format in S3 (available in several providers)
- Configure Vault via bank-vaults

## Architecture

Vault runs in a Docker container in each EC2 instance that join the Raft cluster. The Docker container is spin up by Systemd at bootstrap time and in case of failures, it is automatically restarted. The data directory which contains the data of the node is mounted in the root of the instance.

An Application Load Balancer is deployed internally to the VPC and used during the operation of join the Raft cluster. The Raft Leader address used to join the cluster points to the DNS of the ALB. The health check at the level of the Target Group is set up in the way that the instance looks healthy only when Vault is initialized and unsealed.

### Auto Unseal

The sealing of each node is done automatically via an AWS KMS Key generated with Terraform. The AWS KMS key can be either created or passed as input. In our case we have created a policy and attached to an IAM instance profile. The instance is allowed to use the key to unseal Vault.

### Raft join

The join to Raft cluster is automatically done and run by the tool bank-vaults.

### Configure

Once Vault in unsealed, a root token is created and stored safely on our cloud storage that is S3 but in order to configure the Vault cluster we need to generate a token. It is absolutely discouraged to operate with the root token.

The root token in fact must be exclusively used for bootstrap operations and once done put aside in a safe place.

### Policies

We use policies to govern the behavior of clients and instrument Role-Based Access Control (RBAC) by specifying access privileges (authorization).

Reference: [Vault Policies](https://www.vaultproject.io/docs/concepts/policies)

## Current shortcomings

- Vault cluster nodes are implemented as EC2 instances. In case of failure, the instance doesn't come up automatically. It is necessary to run them as AutoScaling Group. However running them as an AutoScaling Group is not just a matter to change TF resource. Since we are running Vault with Raft as a storage backend, it is important that the EBS volume is always mounted to the correct instance. It is required to have a custom logic implemented in the instance that mount the correct volume at the startup. This is exactly what it happens in our Kubernetes clusters where a daemon named [protokube](https://github.com/kubernetes/kops/tree/master/protokube) runs its logic to mount volume.

- ~~No automatic join of the nodes to the Raft cluster. Nodes after the bootstap phase with Vault already up should join automatic the Raft cluster. This process requires custom logic implementation.~~

- Certificates are self-signed and the CA is created manually. It is required to acquire a CA and generate TLS certificates. It is also required to test the rollout strategy of the certificates.

- Create a KMS policy that allow only instances of the cluster to access to it. This will increase the security and narrow down the scope.

- Writing infra tests using [Terratest](https://github.com/gruntwork-io/terratest).

- Continuous Integration for Vault in Github Action.

- Despite we run Vault in HA backend by Raft as storage provider, it is important that EBS volums are backed up regularly.

- Multi-provider support (AWS, Azure, VMware)

## Operator

In order to solve many of the aforementioned shortcomings, the idea here is to build a tool that would run in each of thee node of the cluster and would take care of operations. This tool would aims to achieve the following things:

- Automatic initialize the cluster by store safely root token and recovery shared keys.

- Automate Raft join.

- Mount external EBS volumes so in case an instance goes down and it is replaced in an ASG, we can still have the data untouched.

- Initialize any internal component of Vault that usually requires manual intervention via CLI/API i.e. Audit backend.

All but one of these features (the mounting of external EBS volume is still required to build our own logic) have been already built in an handy open-sourced CLI tool built by Banzai Cloud named [bank-vaults](https://github.com/banzaicloud/bank-vaults/tree/master/cmd/bank-vaults).

Initially this tool was thought to be used exclusively with Vault clusters created via the their `vault-operator` inside Kubernetes. We have contributed to make this tool more platform-agnostic and use it also in Vault clusters hosted out of Kubernetes.
