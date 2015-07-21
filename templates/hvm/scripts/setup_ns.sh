#!/bin/bash
hostname="$(hostname)"

filename="/var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"
sys-cluster/glusterfs
EOF

emerge -uDN @world

/etc/init.d/glusterd start

rc-update add glusterd default

dirname="/var/glusterfs/tinydns"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

volume="tinydns"
echo "--- $volume (manage)"
gluster volume create ${volume} ${hostmame}:/var/glusterfs/${volume}
gluster volume set ${volume} auth.allow 127.*,10.*
gluster volume start ${volume}

filename="/etc/fstab"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"

localhost:/tinydns	/var/tinydns/root	glusterfs	_netdev		0 0
EOF

dirname="/var/tinydns/root"
echo "--- $dirname (mount)"
mount "${dirname}"

dnscache-conf dnscache dnslog /var/dnscache $(ifconfig eth0 | sed -n -r -e 's/\s+inet (([0-9]{1,3}\.?){4}).*/\1/p')

filename="/var/dnscache/root/ip/10"
echo "--- ${filename} (create)"
touch "${filename}"

filename="/var/dnscache/root/servers/salesteamautomation.com"
echo "--- ${filename} (create)"
cat <<'EOF'>"${filename}"
127.0.0.1
EOF

filename="/var/dnscache/root/servers/10.in-addr.arpa"
echo "--- ${filename} (create)"
cat <<'EOF'>"${filename}"
127.0.0.1
EOF

ln -s /var/dnscache/ /service/dnscache

tinydns-conf tinydns dnslog /var/tinydns 127.0.0.1

ln -s /var/tinydns/ /service/tinydns
