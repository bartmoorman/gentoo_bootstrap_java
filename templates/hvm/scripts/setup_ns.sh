#!/bin/bash
while getopts "p:" OPTNAME; do
	case $OPTNAME in
		p)
			echo "Peer: ${OPTARG}"
			peer="${OPTARG}"
			;;
	esac
done

if [ -z "${peer}" ]; then
	echo "Usage: ${BASH_SOURCE[0]} -p peer_name:peer_ip"
	exit 1
fi

ip="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
name="$(hostname)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="/etc/resolv.conf.head"
echo "--- ${filename} (delete)"
rm "${filename}"

filename="/etc/ntp.conf"
echo "--- ${filename} (restore)"
cp "${filename}.orig" "${filename}"

filename="/etc/ntp.conf"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"
restrict 10.12.0.0 mask 255.255.0.0 nomodify nopeer notrap
EOF

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

${peer#*:}	${peer%:*}.salesteamautomation.com ${peer%:*}
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

emerge -uDN @system @world || exit 1

counter=0
sleep=30
timeout=1800
volume="tinydns"

dirname="/var/glusterfs/${volume}"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

/etc/init.d/glusterd start || exit 1

rc-update add glusterd default

echo -n "Sleeping..."
sleep $(bc <<< "${RANDOM} % 30")
echo "done! :)"

echo -n "Waiting for ${peer%:*}..."

while ! gluster peer probe ${peer%:*} &> /dev/null; do
	if [ "${counter}" -ge "${timeout}" ]; then
		echo "failed! :("
		exit 1
	fi

	echo -n "."
	sleep ${sleep}
	counter=$(bc <<< "${counter} + ${sleep}")
done

echo "connected! :)"

echo -n "Sleeping..."
sleep $(bc <<< "${RANDOM} % 30")
echo "done! :)"

if ! gluster volume info ${volume} &> /dev/null; then
	echo "--- $volume (manage)"
	gluster volume create ${volume} replica 2 ${name}:/var/glusterfs/${volume} ${peer%:*}:/var/glusterfs/${volume} force || exit 1
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
rsync -a "${dirname}.bak/" "${dirname}/" || exit 1

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
