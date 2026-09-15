#!/usr/bin/env bash
set -euo pipefail

# Chạy với quyền root.
if [[ $EUID -ne 0 ]]; then
    echo "Hay chay: sudo bash $0"
    exit 1
fi

# Dừng nếu LAN đã tồn tại, tránh sửa nhầm cấu hình đang chạy.
if ip netns list | awk '{print $1}' | grep -qx kidpcongg-host; then
    echo "Namespace kidpcongg-host da ton tai. Khong tao lai."
    exit 1
fi

for iface in veth-gw veth-host; do
    if ip link show "$iface" >/dev/null 2>&1; then
        echo "Interface $iface da ton tai. Can kiem tra truoc."
        exit 1
    fi
done

# Tạo host và dây mạng ảo nối tới gateway.
ip netns add kidpcongg-host
ip link add veth-gw type veth peer name veth-host
ip link set veth-host netns kidpcongg-host

# Đặt IP cho đầu gateway.
ip addr add 172.16.10.1/24 dev veth-gw
ip link set veth-gw up

# Đặt IP và bật interface trong host.
ip -n kidpcongg-host addr add 172.16.10.10/24 dev veth-host
ip -n kidpcongg-host link set veth-host up
ip -n kidpcongg-host link set lo up

# Cho host biết đường tới mạng VPN.
ip -n kidpcongg-host route add 10.200.0.0/30 via 172.16.10.1
ip -n kidpcongg-host route add 10.10.10.0/24 via 172.16.10.1
echo "Da tao LAN. Dia chi va route cua host:"
ip -n kidpcongg-host -4 -br addr
ip -n kidpcongg-host route
