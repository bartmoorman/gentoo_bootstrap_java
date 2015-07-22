#!/bin/bash
hostname="$(hostname)"
mac="$(curl -s http://169.254.169.254/latest/meta-data/mac)"
if [ -z "${mac}" ]; then
	echo "Unable to determine MAC!"
	exit 1
fi
ip="$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac}/local-ipv4s)"
if [ -z "${ip}" ]; then
	echo "Unable to determine IP!"
	exit 1
fi

filename="/var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"
sys-cluster/glusterfs
EOF

dirname="/etc/portage/package.keywords"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

filename="/etc/portage/package.keywords/glusterfs"
echo "--- ${filename} (create)"
cat <<'EOF'>"${filename}"
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
gluster volume create ${volume} ${hostname}:/var/glusterfs/${volume} force
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

dnscache-conf dnscache dnslog /var/dnscache ${ip}

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
