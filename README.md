# Hybrid Cloud Network Lab

A hands-on learning project connecting a simulated on-premises
Linux network on macOS to AWS through WireGuard VPN.

**Status: In progress — local environment setup.**

## Project goals

- Understand IP addressing, routing, NAT, and firewall policies.
- Connect an on-premises lab to an AWS VPC using WireGuard.
- Automate AWS infrastructure provisioning with Terraform.
- Verify connectivity through packet captures and network logs.
- Document design decisions, failures, and troubleshooting.

## Current environment

| Component | Configuration |
|---|---|
| Host computer | MacBook Air M1, 8 GB RAM |
| Virtualization | UTM |
| Guest operating system | Ubuntu Server 24.04.4 LTS, ARM64 |
| Virtual machine | onprem-gw |
| VM resources | 2 vCPUs, 3 GB RAM |
| Virtual disk | 40 GB, dynamically allocated |
| VM networking | UTM Shared Network |
| Remote access | SSH with public-key authentication |
| Web administration | Cockpit installed; access verification pending |

Ubuntu runs inside UTM. The Mac connects to Ubuntu through SSH.
Cockpit provides a browser-based interface for observing the server.

## Progress

- [x] Create the Ubuntu virtual machine.
- [x] Update Ubuntu packages.
- [x] Configure SSH key authentication.
- [x] Configure the `ssh onprem-gw` connection alias.
- [x] Disable SSH password authentication and direct root login.
- [x] Install Cockpit.
- [x] Create this repository and initial ignore rules.
- [ ] Verify Cockpit access.
- [ ] Build the simulated on-premises LAN.
- [ ] Configure Linux routing and firewall policies.
- [ ] Create AWS networking resources.
- [ ] Establish the WireGuard VPN.
- [ ] Manage AWS infrastructure with Terraform.
- [ ] Capture connectivity and troubleshooting evidence.

## Planned architecture

On-premises workload → Ubuntu gateway → WireGuard tunnel
→ AWS VPN gateway → private application server.

This is the target architecture. End-to-end connectivity
has not been implemented or verified yet.

## Documentation plan

Documentation will be added as each stage is completed:

- Architecture diagram and IP addressing plan.
- Setup instructions and configuration examples.
- Packet flow explanation.
- Connectivity tests and screenshots.
- Troubleshooting notes with causes and fixes.
- AWS resource cleanup instructions.

## Security practices

- Keep private keys, passwords, and cloud credentials out of Git.
- Use placeholder values in configuration examples.
- Review files and screenshots before committing them.
- Do not commit VM disks, installation images, or Terraform state.

## Learning approach

For each lab stage, record:

1. What I wanted to achieve.
2. What I configured and why.
3. How I tested the result.
4. What failed and how I investigated it.
5. What I learned.

## Scope and limitations

This is an educational lab under active development.
It is not a production deployment or a highly available system.
