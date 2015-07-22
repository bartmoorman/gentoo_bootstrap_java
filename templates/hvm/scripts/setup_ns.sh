#!/bin/bash
hostname="$(hostname)"
if [ "${hostname:(-3)}" == "ns1" ]; then
	peer_name="${hostname::(-3)}ns2"
	peer_ip="10.12.32.10"
elif [ "${hostname:(-3)}" == "ns2" ]; then
	peer_name="${hostname::(-3)}ns1"
	peer_ip="10.12.16.10"
fi
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

counter=0
sleep=3
timeout=600
volume="tinydns"

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

tinydns-conf tinydns dnslog /var/tinydns 127.0.0.1

filename="/etc/hosts"
echo "--- ${filename} (append)"
cat <<EOF>>"${filename}"

${peer_ip}	${peer_name}.salesteamautomation.com ${peer_name}
EOF

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

dirname="/var/glusterfs/${volume}"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

/etc/init.d/glusterd start

rc-update add glusterd default

echo -n "Sleeping..."
sleep 10
echo "done! :)"

echo -n "Waiting for ${peer_name}"

while ! gluster peer probe ${peer_name} &> /dev/null; do
	if [ "${counter}" -ge "${timeout}" ]; then
		echo "failed! :("
		exit 1
	fi

	echo -n "."
	sleep ${sleep}
	counter=$(bc <<< "${counter} + ${sleep}")
done

echo "connected! :)"

if ! gluster volume info ${volume} &> /dev/null; then
	echo "--- $volume (manage)"
	gluster volume create ${volume} replica 2 ${hostname}:/var/glusterfs/${volume} ${peer_name}:/var/glusterfs/${volume} force
	gluster volume set ${volume} auth.allow 127.*,10.*
	gluster volume start ${volume}
fi

filename="/etc/fstab"
echo "--- ${filename} (append)"
cat <<EOF>>"${filename}"

localhost:/${volume}	/var/tinydns/root	glusterfs	_netdev		0 0
EOF

dirname="/var/tinydns/root"
echo "--- $dirname (mount)"
mv "${dirname}" "${dirname}.bak"
mkdir ${dirname}
mount "${dirname}"
rsync -a "${dirname}.bak/" "${dirname}"

ln -s /var/dnscache/ /service/dnscache
ln -s /var/tinydns/ /service/tinydns
