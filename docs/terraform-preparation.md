# Terraform preparation — 2026-09-15

## Completed
- Installed Terraform v1.16.0 for macOS ARM64.
- Installed AWS CLI v2.36.45.
- Attached SignInLocalDevelopmentAccess directly to IAM user kidpcongg-lab.
- Signed in using: aws login --profile hcn-lab
- Verified IAM identity using:
  aws sts get-caller-identity --profile hcn-lab
- Verified CLI can describe the two EC2 instances in Singapore:
  - hcn-vpn-gw: 10.10.1.130
  - hcn-private-app: 10.10.10.7
- Verified the private application remained reachable after restarting
  the environment and recreating the simulated on-premises LAN.

## Next session
1. Start both EC2 instances and the local Ubuntu VM.
2. Check the VPN gateway's current public IPv4 address.
3. Update the local WireGuard endpoint if that address changed.
4. Recreate the local LAN using ~/hcn-lab/start-local-lan.sh.
5. Verify access to http://10.10.10.7:8000/ from kidpcongg-host.
6. Review .gitignore before creating Terraform configuration.
7. Continue Terraform under infra/terraform/.

## Terraform status
- No Terraform configuration has been written.
- No terraform apply or import has been performed.
- Existing AWS resources are still manually managed.
- An empty infra/terraform/ directory is not tracked by Git.
