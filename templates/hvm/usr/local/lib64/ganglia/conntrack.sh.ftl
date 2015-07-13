#!/bin/bash
max=$(cat /proc/sys/net/ipv4/netfilter/ip_conntrack_max)
count=$(cat /proc/sys/net/ipv4/netfilter/ip_conntrack_count)
percent=$(bc <<< "scale=2; ${count} * 100 / ${max}")

/usr/bin/gmetric -n "ipv4_conntrack" -v "${percent}" -t "float" -u "%"
