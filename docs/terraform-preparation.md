# Terraform Implementation

## Outcome

The manually created AWS lab was adopted into Terraform without replacing or
destroying the working infrastructure. Terraform now manages the VPC network,
EC2 instances, security groups, routing, and VPC Flow Logs configuration.

The final verification reported:

```text
No changes. Your infrastructure matches the configuration.
```

## Tooling and authentication

- Terraform `v1.16.0` on macOS ARM64.
- AWS CLI `v2.36.45`.
- Region: `ap-southeast-1`.
- Daily work performed through the named profile `hcn-lab` and IAM user
  `kidpcongg-lab`, rather than the AWS root user.

Authentication was verified before Terraform operations:

```bash
aws login --profile hcn-lab
aws sts get-caller-identity --profile hcn-lab
```

The real administrator CIDR is stored in `terraform.tfvars`, which is ignored
by Git. `terraform.tfvars.example` shows the required format using a
documentation-only address.

## Adoption workflow

The resources already existed because they were first built manually for
learning and troubleshooting. They were therefore imported instead of being
created a second time.

The safe import workflow was:

1. Inventory the actual AWS IDs and settings.
2. Write minimal Terraform resource configuration.
3. Define import blocks for the existing resources.
4. Run `terraform fmt` and `terraform validate`.
5. Review the plan for replacements, changes, and destruction.
6. Correct configuration drift until the plan showed:

   ```text
   11 to import, 0 to add, 0 to change, 0 to destroy
   ```

7. Apply the saved import plan.
8. Remove the temporary import blocks and saved plan.
9. Add the explicit private-subnet route-table association through Terraform.
10. Confirm a clean plan.

Importing updated Terraform state only; it did not rebuild the live resources.

## Managed infrastructure

Core resources:

- VPC and Internet Gateway.
- Public and private subnets.
- Public and private route tables and their subnet associations.
- VPN gateway and private application EC2 instances.
- VPN and private-application security groups.

Monitoring resources:

- VPC Flow Log configured for `ALL` traffic.
- CloudWatch Logs group with seven-day retention.
- IAM delivery role and policy used by VPC Flow Logs.

The current Terraform state contains 16 managed resources: 12 core resources
and four monitoring resources.

## Monitoring verification

VPC Flow Logs reported an active status and successful log delivery to the
CloudWatch Logs group. Flow Logs provide metadata such as interfaces, source
and destination addresses, ports, protocol, byte counts, and accept/reject
decisions. They do not contain application payloads and do not replace packet
capture with `tcpdump`.

## Important implementation decisions

- The VPN gateway has source/destination checking disabled because it forwards
  traffic for other hosts.
- The private route table sends `172.16.10.0/24` to the VPN gateway ENI.
- The private application has no public IPv4 address.
- SSH and WireGuard ingress use the administrator's current `/32` address.
- Saved plans, state, credentials, private keys, and real variable values are
  excluded from version control.
- The imported VPN gateway preserves its observed public-IP association
  behavior to avoid replacing a working instance.

## What Terraform does not yet automate

- Creation of the EC2 key pair used by the instances.
- WireGuard private keys and guest operating-system configuration.
- Deployment of the private application service.
- Construction of the UTM virtual machine.
- Recreation of the Linux namespace and veth pair; that is handled by
  `scripts/start-local-lan.sh`.

These limitations are intentional for this educational version and are stated
so that the repository does not overclaim full reproducibility.

## Safe operating procedure

Before any plan or apply:

```bash
aws login --profile hcn-lab
aws sts get-caller-identity --profile hcn-lab
terraform -chdir=infra/terraform fmt -check
terraform -chdir=infra/terraform validate
terraform -chdir=infra/terraform plan
```

Never apply a plan that contains an unexplained replacement or destroy action.
In particular, imported resources must be compared carefully with their live
AWS configuration.

## Cleanup policy

Stopping the two EC2 instances stops compute usage but does not remove every
possible charge; EBS volumes and CloudWatch Logs can remain billable.

Before destroying this lab:

1. Confirm the latest code and documentation are pushed to GitHub.
2. Back up Terraform state securely outside the repository.
3. Generate and review a saved `terraform plan -destroy`.
4. Confirm exactly which managed and unmanaged resources will remain.
5. Apply the destroy plan only after explicit approval.
6. Verify the result in AWS and review Cost Explorer/Billing afterward.

The AWS Budget, IAM user and permissions, EC2 key pair, local UTM VM, GitHub
repository, and local evidence are outside this Terraform state and require
separate retention or cleanup decisions.
