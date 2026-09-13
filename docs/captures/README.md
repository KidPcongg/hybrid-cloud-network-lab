
# Packet Capture Evidence

## ICMP connectivity from Ubuntu to the Internet

File: `ping-internet-20260909-115045.pcap`

### Environment
- Capture interface: `enp0s1` on Ubuntu VM `onprem-gw`.
- Ubuntu IP: `192.168.64.5`.
- Default gateway: `192.168.64.1`.
- Ping destination: `8.8.8.8`.

### Method
Captured traffic with tcpdump using this filter:

`icmp and host 8.8.8.8`

Generated traffic in a second SSH session:

`ping -c 4 8.8.8.8`

### Observed result
- Captured 4 ICMP echo requests and 4 matching replies.
- The capture contains IP traffic between the VM and `8.8.8.8`.
- Saved the capture, copied it to macOS with scp, and read it again.

### Interpretation and limits
The capture demonstrates successful ICMP request/reply exchanges
with an external IP during this test.

The destination IP remains `8.8.8.8`, while the routing table
selects `192.168.64.1` as the next hop.

This capture was taken inside the VM. It does not show
the complete Internet path or the translated source IP after NAT.
It does not test DNS, HTTPS, or VPN connectivity.

### Read the capture
From the repository root:

`tcpdump -nn -r docs/captures/ping-internet-20260909-115045.pcap
