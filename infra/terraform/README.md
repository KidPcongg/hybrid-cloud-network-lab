# AWS Infrastructure with Terraform

This directory contains Terraform configuration for the AWS portion of the
Hybrid Cloud Network Lab. The configuration was written after the lab was built
manually, then the existing resources were safely imported into state.

## Managed resources

- VPC `10.10.0.0/16` and Internet Gateway.
- Public subnet `10.10.1.0/24`.
- Private subnet `10.10.10.0/24`.
- Public and private route tables and subnet associations.
- EC2 WireGuard gateway and private application instance.
- Security groups for VPN administration and private application access.
- VPC Flow Logs, CloudWatch Logs group, and Flow Logs delivery IAM resources.

The current state contains 16 managed resources. Guest configuration such as
WireGuard keys, operating-system packages, and application deployment is not
fully automated here.

## Prerequisites

- Terraform compatible with the version constraint in `versions.tf`.
- AWS CLI authenticated to the intended account.
- Access to `ap-southeast-1` through AWS profile `hcn-lab`.
- The existing EC2 key pair referenced by the instance resources.

Verify identity before continuing:

```bash
aws login --profile hcn-lab
aws sts get-caller-identity --profile hcn-lab
```

## Local variables

Copy the example file and replace the documentation address with the current
administrator public IPv4 address:

```bash
cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
```

Example:

```hcl
admin_cidr = "203.0.113.10/32"
```

Keep the `/32` suffix to allow SSH and WireGuard only from one public IPv4
address. `terraform.tfvars` is intentionally ignored by Git.

## Validate and inspect

Run from the repository root:

```bash
terraform -chdir=infra/terraform init
terraform -chdir=infra/terraform fmt -check
terraform -chdir=infra/terraform validate
terraform -chdir=infra/terraform plan
```

Read the entire plan before applying. A normal steady-state result is:

```text
No changes. Your infrastructure matches the configuration.
```

Do not apply if Terraform proposes an unexplained replacement or destruction.

## State and secret handling

The following files must remain local and must never be committed or shared:

- `terraform.tfstate` and state backups.
- Saved `.tfplan` files.
- `terraform.tfvars` containing the real administrator CIDR.
- AWS credentials, SSH private keys, and WireGuard private keys.

The repository tracks `.terraform.lock.hcl` so provider selection is
repeatable, but it ignores the downloaded `.terraform/` directory.

## Imported-infrastructure note

The original infrastructure was created manually and later imported. Import
blocks and import plan files were temporary and were removed after successful
adoption. The accepted import operation reported 11 imported resources with
zero resources added, changed, or destroyed. Terraform subsequently created
the explicit private-subnet route-table association.

For the full history and design decisions, see
[`../../docs/terraform-preparation.md`](../../docs/terraform-preparation.md).

## Destruction safety

Do not run `terraform destroy` casually. First create a saved destroy plan and
review every target:

```bash
terraform -chdir=infra/terraform plan \
  -destroy \
  -out=hcn-destroy.tfplan
```

Applying that plan should happen only after confirming that the GitHub
portfolio and a secure local state backup are complete. Resources outside this
state—including the AWS Budget, IAM login, EC2 key pair, and local UTM VM—will
not be deleted by Terraform.
