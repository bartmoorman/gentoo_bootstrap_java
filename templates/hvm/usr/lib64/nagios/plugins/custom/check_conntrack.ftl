#!/bin/bash
warning=.80
critical=.90

max=$(cat /proc/sys/net/ipv4/netfilter/ip_conntrack_max)
count=$(cat /proc/sys/net/ipv4/netfilter/ip_conntrack_count)
percent=$(bc <<< "scale=2; <#noparse>${count}</#noparse> * 100 / <#noparse>${max}</#noparse>")

if [ $(bc <<< "<#noparse>${max}</#noparse> * <#noparse>${critical}</#noparse> < <#noparse>${count}</#noparse>") -eq 1 ]
then
	echo "CRITICAL: <#noparse>${count}</#noparse> connections (<#noparse>${percent}</#noparse>%)"
	exit 2
elif [ $(bc <<< "<#noparse>${max}</#noparse> * <#noparse>${warning}</#noparse> < <#noparse>${count}</#noparse>") -eq 1 ]
then
	echo "WARNING: <#noparse>${count}</#noparse> connections (<#noparse>${percent}</#noparse>%)"
	exit 1
else
	echo "OK: <#noparse>${count}</#noparse> connections (<#noparse>${percent}</#noparse>%)"
	exit 0
fi
