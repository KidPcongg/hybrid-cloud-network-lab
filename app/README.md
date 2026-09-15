# HCN private application

A static HTTP demo running on the private EC2 instance
hcn-private-app (10.10.10.7), without a public IPv4 address.

## Files

- index.html: demo page.
- hcn-app.service: systemd service running Python's HTTP server.

## Deployment on the private instance

Place index.html in /home/ubuntu/hcn-app/ and install
hcn-app.service in /etc/systemd/system/, then run:

    sudo systemctl daemon-reload
    sudo systemctl enable --now hcn-app

The service uses user ubuntu and binds to 10.10.10.7:8000.
Adjust the address and paths if deploying on another instance.

## Verification from the local Ubuntu gateway

    sudo ip netns exec kidpcongg-host curl --fail --connect-timeout 5 --max-time 10 http://10.10.10.7:8000/

On 2026-09-15, the service reported active and enabled,
and the simulated on-premises host successfully retrieved
the page through WireGuard.

Evidence: [Ping and HTTP response](../docs/screenshots/onprem-to-private-app-success-2026-09-15.png).

## Scope

This Python HTTP server is for the lab demo.
Service autostart is configured; application recovery
after an EC2 reboot has not yet been tested.
