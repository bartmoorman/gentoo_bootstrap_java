#!/bin/bash
max=$(cat /proc/sys/net/ipv4/netfilter/ip_conntrack_max)
count=$(cat /proc/sys/net/ipv4/netfilter/ip_conntrack_count)
percent=$(bc <<< "scale=2; <#noparse>${count}</#noparse> * 100 / <#noparse>${max}</#noparse>")

/usr/bin/gmetric -n "ipv4_conntrack" -v "<#noparse>${percent}</#noparse>" -t "float" -u "%"
