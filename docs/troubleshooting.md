# Troubleshooting Notes

This document records failures encountered while building the lab, the method
used to isolate each fault, and the evidence used to verify the fix.

## 001 — Git clone failed because of an extra space

**Symptom:** Git reported an invalid repository name.

**Incorrect command:**

```bash
git clone git@github-personal: KidPcongg/hybrid-cloud-network-lab.git
```

**Cause:** The space after the colon split the repository address into two
command-line arguments.

**Fix and verification:** Remove the space, clone again, and confirm that
`git status` reports the expected branch and a clean worktree.

```bash
git clone git@github-personal:KidPcongg/hybrid-cloud-network-lab.git
```

## 002 — A successful ping was caused by a duplicate veth address

**Symptom:** The namespace appeared to reach the gateway, but both ends of the
veth pair had been assigned `172.16.10.1/24`.

**Cause:** The namespace was pinging an address configured locally rather than
proving communication across the veth link.

**Fix:** Keep `172.16.10.1/24` on `veth-gw` and assign
`172.16.10.10/24` to `veth-host` inside `kidpcongg-host`.

**Verification:** Inspect both interfaces before pinging:

```bash
ip -4 -br addr
sudo ip -n kidpcongg-host -4 -br addr
sudo ip netns exec kidpcongg-host ping -c 4 172.16.10.1
```

**Lesson:** A successful ping is meaningful only after confirming the source,
destination, interfaces, and route.

## 003 — SSH to EC2 timed out

**Symptom:**

```text
ssh: connect to host <public-ip> port 22: Operation timed out
```

**Cause:** The home public IPv4 had changed while the VPN security group still
allowed only the previous `/32` address.

**Fix:** Update the Terraform `admin_cidr` value to the current public IPv4
with a `/32` suffix and review the plan before applying it.

**Verification:** SSH reached the host-key prompt and then opened an Ubuntu
session using the configured private key.

## 004 — `wg-quick` reported that `wg0` did not exist

**Symptom:**

```text
Unable to modify interface: No such device
Unable to access interface: No such device
```

**Cause:** The configuration tried to load the private key in a `PreUp` hook
before `wg-quick` had created the interface.

**Fix:** Load the protected key after interface creation using the working
`PostUp` arrangement used by this lab.

**Verification:**

```bash
sudo wg-quick up wg0
sudo wg show wg0
```

The interface appeared with the expected public key and listening port.

## 005 — WireGuard sent data but received no replies after EC2 restart

**Symptom:** `wg show` displayed sent bytes but zero received bytes, and ping to
`10.200.0.1` failed.

**Cause:** Stopping and starting the VPN EC2 instance assigned it a different
public IPv4 address. The local peer still used the old endpoint.

**Fix:** Read the current EC2 public IPv4, update only the endpoint address, and
keep UDP port 51820:

```ini
Endpoint = CURRENT_PUBLIC_IPV4:51820
```

**Verification:** `wg show` displayed a recent handshake and increasing send
and receive counters; tunnel ping returned four replies.

## 006 — The tunnel worked, but the namespace could not reach AWS

**Symptom:** The local gateway could ping the AWS tunnel address, while
`kidpcongg-host` received no replies.

**Cause:** `net.ipv4.ip_forward` was `0`, so the Ubuntu gateway did not forward
packets between the veth interface and `wg0`.

**Fix:** Enable IPv4 forwarding and save it under
`/etc/sysctl.d/99-hcn-forwarding.conf`.

**Verification:**

```bash
sysctl net.ipv4.ip_forward
sudo ip netns exec kidpcongg-host ping -c 4 10.200.0.1
sudo tcpdump -ni wg0 icmp
```

The namespace received replies, and `tcpdump` observed both requests and
responses on `wg0`.

## 007 — Tunnel connectivity alone did not reach the private application

**Required components:**

- A namespace route for `10.10.10.0/24` through `172.16.10.1`.
- `10.10.10.0/24` in the local WireGuard peer's `AllowedIPs`.
- IPv4 forwarding on both Linux gateways.
- EC2 source/destination check disabled on the VPN gateway.
- A private-subnet route for `172.16.10.0/24` targeting the VPN gateway ENI.
- Private-app security-group rules allowing ICMP and TCP 8000 from
  `172.16.10.0/24`.

**Verification:**

```bash
sudo ip -n kidpcongg-host route get 10.10.10.7
sudo ip netns exec kidpcongg-host ping -c 4 10.10.10.7
sudo ip netns exec kidpcongg-host curl http://10.10.10.7:8000/
```

Both ICMP and HTTP succeeded. Testing the application protocol was necessary
because a successful ping does not prove that TCP 8000 or the service works.

## 008 — Automatic Terraform configuration generation failed

**Symptoms:** Generated configuration contained conflicting arguments, empty
CIDR values, and an invalid route-table-association import identifier.

**Cause:** Terraform's configuration generation was experimental and included
computed AWS attributes that should not all be declared together. The
association import also required `subnet-id/route-table-id`, not the association
ID alone.

**Fix:** Write a minimal readable configuration, correct the association import
identifier, format and validate it, then inspect a non-destructive import plan.

**Safety check:** The accepted plan showed:

```text
11 to import, 0 to add, 0 to change, 0 to destroy
```

Importing records existing infrastructure in Terraform state; it does not
recreate a resource when the plan shows zero changes.

## 009 — Terraform proposed replacing the VPN gateway

**Symptom:** The plan showed `associate_public_ip_address: false -> true` and
marked the EC2 gateway for replacement.

**Risk:** Applying that plan would destroy the working gateway and its manually
configured WireGuard installation.

**Fix:** Stop before apply, compare configuration with observed AWS state, and
ignore the provider-reported public-IP-association difference for this imported
instance. Re-run the plan until it reports zero destroy operations.

**Lesson:** Never approve a Terraform plan based only on valid syntax. Read the
resource action symbols and investigate every replacement or destroy action.

## 010 — AWS CLI login token expired

**Symptom:** Terraform reported no valid credential source and an expired or
invalid OAuth authorization grant.

**Fix:** Refresh the named IAM profile and verify the caller before retrying:

```bash
aws logout --profile hcn-lab
aws login --profile hcn-lab
aws sts get-caller-identity --profile hcn-lab
```

**Verification:** The returned ARN identified the intended IAM user, after
which Terraform could refresh the AWS resources.

## Troubleshooting method used throughout the lab

1. Confirm which machine and shell are active.
2. Inspect addresses with `ip -4 -br addr`.
3. Ask the kernel for the selected route with `ip route get`.
4. Check forwarding, firewall, security group, and source/destination check.
5. Check WireGuard handshake, endpoint, `AllowedIPs`, and transfer counters.
6. Capture packets at the relevant interface with `tcpdump`.
7. Test both ICMP and the real application protocol.
8. Record the failure, correction, and post-fix evidence.
