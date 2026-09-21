# Screenshot Evidence

This directory contains dated evidence from the Hybrid Cloud Network Lab.
Screenshots document configuration and validation results; sensitive values
such as private keys and credentials are not included.

## Evidence summary

| Stage | Evidence | What it demonstrates |
|---|---|---|
| AWS account | [Free plan credit](aws-free-plan-initial-credit-2026-09-12.png) | Account credit observed on the capture date. |
| Cost control | [AWS budget](aws-budget-created-2026-09-13.png) | Monthly cost alerts were configured. |
| VPC | [Public subnet](aws-subnet-public-created.png) and [private subnet](aws-subnet-private-created.png) | Separation of the VPN gateway and private workload. |
| Internet routing | [Internet Gateway](aws-internet-gateway-attached.png), [public route table](aws-public-route-table-created.png), [default route](aws-public-route-created.png), and [subnet association](aws-public-subnet-associated.png) | Public-subnet routing through the Internet Gateway. |
| Firewall | [VPN security group](aws-vpn-security-group-created.png) | SSH and WireGuard ingress restricted to one administrator IPv4 `/32`. |
| EC2 access | [Successful SSH login](aws-ec2-ssh-success-2026-09-14.png) | Administrative access to the AWS VPN gateway. |
| Local networking | [Duplicate-IP correction](fix-duplicate-ip-veth-2026-09-10.png) | Correct addressing across the simulated LAN veth pair. |
| WireGuard | [Tunnel handshake and ping](wireguard-tunnel-ping-success-2026-09-14.png) | Working encrypted tunnel between the local and AWS gateways. |
| Routed LAN traffic | [Namespace-to-AWS ping](onprem-host-to-aws-vpn-ping-success-2026-09-14.png) | Traffic from the simulated on-premises host reached AWS. |
| Packet inspection | [ICMP capture on AWS `wg0`](aws-wg0-host-icmp-capture-2026-09-14.png) | Inner packets retained source `172.16.10.10`; no SNAT was used. |
| Private workload | [Private application test](onprem-to-private-app-success-2026-09-15.png) | The on-premises namespace reached `10.10.10.7:8000`. |
| Final validation | [Restart and end-to-end test](hcn-final-end-to-end-2026-09-20.png) | The environment was reconstructed and private connectivity retested successfully. |

## 1. Local LAN correction — 2026-09-10

The two ends of the veth pair were initially assigned the same address.
That made a successful ping misleading because the namespace could reach its
own address rather than the gateway.

Final addressing:

| Node | Interface | Address |
|---|---|---|
| Ubuntu on-premises gateway | `veth-gw` | `172.16.10.1/24` |
| Simulated host namespace | `veth-host` | `172.16.10.10/24` |

After correcting the host address, four ICMP replies from `172.16.10.1`
verified the veth link. This incident is documented further in
[Troubleshooting Notes](../troubleshooting.md).

## 2. AWS cost and network baseline — 2026-09-12 to 2026-09-13

An AWS Budget named `hcn-lab-monthly-cost` was configured with a USD 10
monthly threshold and actual-cost email alerts at 50% and 100%. A budget
sends notifications; it is not a hard spending limit.

The network foundation was created in `ap-southeast-1`:

| Component | Configuration |
|---|---|
| VPC | `10.10.0.0/16` |
| Public subnet | `10.10.1.0/24` |
| Private subnet | `10.10.10.0/24` |
| Public route | `0.0.0.0/0` to the Internet Gateway |
| Private return route | `172.16.10.0/24` to the VPN gateway ENI |

A subnet becomes public through its effective routing and instance addressing,
not through its name. The private application has no public IPv4 address.

The VPN security group allowed TCP 22 and UDP 51820 only from the current
administrator public IPv4 `/32`. Because that IPv4 can change, the value is
kept in the ignored `terraform.tfvars` file rather than committed to Git.

## 3. EC2 and WireGuard — 2026-09-14

The AWS VPN gateway runs Ubuntu Server 24.04 on a `t3.micro` instance in the
public subnet. SSH access was verified using key authentication.

WireGuard addressing:

| Endpoint | Tunnel address |
|---|---|
| AWS VPN gateway | `10.200.0.1/30` |
| Local Ubuntu gateway | `10.200.0.2/30` |

The AWS endpoint listens on UDP 51820. The local peer uses
`PersistentKeepalive = 25` so a NAT mapping can remain active. A recent
handshake, increasing transfer counters, and successful ping in both
directions confirmed tunnel operation.

Private WireGuard keys remain on their respective machines and are excluded
from the repository.

## 4. Routed host traffic and packet capture — 2026-09-14

The namespace was configured with routes through `172.16.10.1`, while IPv4
forwarding was enabled on the local gateway. On AWS, the peer configuration
included `172.16.10.0/24` in `AllowedIPs`.

Validation command:

```bash
sudo ip netns exec kidpcongg-host ping -c 4 10.200.0.1
```

The result was four transmitted and four received packets. An AWS-side capture:

```bash
sudo tcpdump -ni wg0 icmp
```

showed four echo requests and four matching replies between `172.16.10.10`
and `10.200.0.1`. This capture shows decrypted inner IP traffic on `wg0`, not
the encrypted outer UDP packets on the internet-facing interface.

## 5. Private application — 2026-09-15

The private EC2 instance uses address `10.10.10.7` and serves a small HTTP
application on TCP 8000. From the simulated on-premises host:

```bash
sudo ip netns exec kidpcongg-host ping -c 4 10.10.10.7
sudo ip netns exec kidpcongg-host \
  curl --connect-timeout 5 --max-time 10 http://10.10.10.7:8000/
```

The ping received four replies and the HTTP request returned the application
page. This is stronger evidence than pinging only the tunnel endpoint: it
demonstrates routed application traffic between the on-premises LAN and an
AWS instance that has no public IPv4 address.

## 6. Final reconstruction test — 2026-09-20

After restarting the environment:

1. The EC2 instances and local UTM VM were started.
2. The local WireGuard endpoint was updated to the VPN gateway's current
   public IPv4 address.
3. `scripts/start-local-lan.sh` recreated the namespace, veth pair, addressing,
   and routes.
4. The namespace again received four ping replies from `10.10.10.7`.
5. The HTTP request again returned the private application page.

This final test verifies that the documented recovery procedure works after
the ephemeral namespace network has been removed by a VM shutdown.

## 7. Infrastructure as Code and monitoring

Terraform now manages the existing AWS network, compute, security, and
monitoring resources. The import plan completed with:

```text
11 to import, 0 to add, 0 to change, 0 to destroy
```

Terraform then created the explicit private-subnet route-table association.
The final core infrastructure plan reported no drift. VPC Flow Logs were also
enabled for `ALL` traffic and delivered successfully to a CloudWatch Logs group
with seven-day retention.

Terraform source is available under [`../../infra/terraform/`](../../infra/terraform/).
State files, saved plans, credentials, real variable files, and private keys
are intentionally excluded from Git.

## Evidence limitations

- Screenshots prove the state observed at the capture time, not continuous
  availability or production readiness.
- This is a single-region, single-AZ educational design without redundancy.
- The EC2 public IPv4 can change after stop/start because no Elastic IP is used.
- Guest operating-system setup, WireGuard keys, and the application deployment
  are documented but are not fully automated by Terraform.
