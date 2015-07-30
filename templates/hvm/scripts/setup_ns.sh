#!/bin/bash
name="$(hostname)"
ip="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

while getopts "i:n:" OPTNAME; do
	case $OPTNAME in
		i)
			echo "Peer IP: ${OPTARG}"
			peer_ip="${OPTARG}"
			;;
		n)
			echo "Peer Name: ${OPTARG}"
			peer_name="${OPTARG}"
			;;
	esac
done

if [ -z "${peer_ip}" -o -z "${peer_name}" ]; then
	echo "Usage: $0 -n peer_name -i peer_ip"
	exit 1
fi

scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="/etc/resolv.conf.head"
echo "--- ${filename} (delete)"
rm "${filename}"

kill -HUP $(pgrep ^dhcpcd) || exit 1

svc -d /service/dnscache || exit 1

filename="/var/dnscache/env/FORWARDONLY"
echo "--- ${filename} (delete)"
rm "${filename}"

filename="/var/dnscache/env/IP"
echo "--- ${filename} (replace)"
cat <<EOF>"${filename}"
${ip}
EOF

filename="/var/dnscache/root/servers/@"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
198.41.0.4
192.228.79.201
192.33.4.12
199.7.91.13
192.203.230.10
192.5.5.241
192.112.36.4
128.63.2.53
192.36.148.17
192.58.128.30
193.0.14.129
199.7.83.42
202.12.27.33
EOF

filename="/var/dnscache/root/servers/salesteamautomation.com"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
127.0.0.1
EOF

filename="/var/dnscache/root/servers/12.10.in-addr.arpa"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
127.0.0.1
EOF

filename="/var/dnscache/root/ip/10.12"
echo "--- ${filename} (create)"
touch "${filename}"

svc -u /service/dnscache || exit 1

tinydns-conf tinydns dnslog /var/tinydns 127.0.0.1 || exit 1

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
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
sys-cluster/glusterfs
EOF

emerge -uDN @world || exit 1

counter=0
sleep=3
timeout=600
volume="tinydns"

dirname="/var/glusterfs/${volume}"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

/etc/init.d/glusterd start || exit 1

rc-update add glusterd default

echo -n "Sleeping..."
sleep 10
echo "done! :)"

echo -n "Waiting for ${peer_name}..."

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
	gluster volume create ${volume} replica 2 ${name}:/var/glusterfs/${volume} ${peer_name}:/var/glusterfs/${volume} force || exit 1
	gluster volume set ${volume} auth.allow 127.*,10.12.*
	gluster volume start ${volume} || exit 1
fi

filename="/etc/fstab"
echo "--- ${filename} (append)"
cat <<EOF>>"${filename}"

localhost:/${volume}	/var/tinydns/root	glusterfs	_netdev		0 0
EOF

dirname="/var/tinydns/root"
echo "--- $dirname (mount)"
mv "${dirname}" "${dirname}.bak" || exit 1
mkdir -p "${dirname}"
mount "${dirname}" || exit 1
rsync -a "${dirname}.bak/" "${dirname}" || exit 1

ln -s /var/tinydns/ /service/tinydns

dirname="/usr/local/lib64/nsupdater"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

filename="/usr/local/lib64/nsupdater/index.php"
echo "--- ${filename} (replacee)"
curl -sf -o "${filename}" "${scripts}${filename}" || exit 1

filename="/etc/init.d/nsupdater"
echo "--- ${filename} (replace)"
curl -sf -o "${filename}" "${scripts}${filename}" || exit 1
chmod 755 "${filename}"

/etc/init.d/nsupdater start || exit 1

rc-update add nsupdater default
