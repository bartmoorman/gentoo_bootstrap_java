#!/bin/bash
while getopts ":p:" OPTNAME; do
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
iam_role="$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="etc/resolv.conf.head"
echo "--- ${filename} (delete)"
rm "/${filename}" || exit 1

filename="etc/conf.d/net"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
dhcp_eth0="nontp"
EOF

kill -HUP $(pgrep ^dhcpcd) || exit 1

filename="etc/ntp.conf"
echo "--- ${filename} (restore)"
mv "/${filename}.orig" "/${filename}" || exit 1

filename="etc/ntp.conf"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
restrict 10.0.0.0 mask 255.0.0.0 nomodify nopeer notrap
EOF

svc -d /service/dnscache || exit 1

filename="var/dnscache/env/IP"
echo "--- ${filename} (replace)"
cat <<EOF>"/${filename}"
${ip}
EOF

filename="var/dnscache/root/servers/@"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
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

filename="var/dnscache/root/servers/salesteamautomation.com"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
127.0.0.1
EOF

filename="var/dnscache/root/servers/10.in-addr.arpa"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
127.0.0.1
EOF

filename="var/dnscache/root/ip/10"
echo "--- ${filename} (create)"
touch "/${filename}" || exit 1

svc -u /service/dnscache || exit 1

tinydns-conf tinydns dnslog /var/tinydns 127.0.0.1 || exit 1

filename="etc/hosts"
echo "--- ${filename} (append)"
cat <<EOF>>"/${filename}"

${peer#*:}	${peer%:*}.salesteamautomation.com ${peer%:*}
EOF

emerge -q --sync || exit 1

dirname="etc/portage/repos.conf"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/portage/repos.conf/gentoo.conf"
echo "--- ${filename} (replace)"
cp "/usr/share/portage/config/repos.conf" "/${filename}" || exit 1
sed -i -r \
-e "\|^\[gentoo\]$|,\|^$|s|^(sync\-uri\s+\=\s+rsync\://).*|\1${hostname_prefix}systems1/gentoo\-portage|" \
"/${filename}"

filename="var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
sys-cluster/glusterfs
EOF

dirname="etc/portage/package.keywords"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/portage/package.keywords/glusterfs"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
sys-cluster/glusterfs
EOF

mirrorselect -D -c Ireland -R Europe -s5 || exit 1

emerge -uDN @system @world || emerge --resume || exit 1

filename="etc/portage/make.conf"
echo "--- ${filename} (modify)"
sed -i -r \
-e "\|^EMERGE_DEFAULT_OPTS|a PORTAGE_BINHOST\=\"http\://${hostname_prefix}bin1/packages\"" \
"/${filename}" || exit 1

counter=0
timeout=1800
volume="tinydns"

part=30
position=0

if [ "${ip}" \> "${peer#*:}" ]; then
	position=$(bc <<< "${position} + 1")
fi

low=$(bc <<< "(${part} * ${position}) + 5")
high=$(bc <<< "((${part} * ${position}) + ${part}) - 5")
range=($(seq -s' ' ${low} ${high}))
index=$(bc <<< "${RANDOM} % ${#range[@]}")
sleep=${range[${index}]}

dirname="var/glusterfs/${volume}"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

/etc/init.d/glusterd start || exit 1

rc-update add glusterd default

echo -n "Sleeping (${sleep}s)..."
sleep ${sleep}
echo "done! :)"

echo -n "Waiting for ${peer%:*}..."

while true; do
	gluster peer probe ${peer%:*} &> /dev/null && break

	if [ "${counter}" -ge "${timeout}" ]; then
		echo "failed! :("
		exit 1
	fi

	echo -n "."
	sleep ${sleep}
	counter=$(bc <<< "${counter} + ${sleep}")
done

echo "connected! :)"

echo -n "Sleeping (${sleep}s)..."
sleep ${sleep}
echo "done! :)"

if ! gluster volume info ${volume} &> /dev/null; then
	echo "--- ${volume} (manage)"
	gluster volume create ${volume} replica 2 ${name}:/var/glusterfs/${volume} ${peer%:*}:/var/glusterfs/${volume} force || exit 1
	gluster volume set ${volume} auth.allow 127.*,10.*
	gluster volume start ${volume} || exit 1
fi

filename="var/tinydns/root/data"
echo "--- ${filename} (replace)"
cat <<EOF>"/${filename}"
#
# loc
#
%lo:127
%lo:10
%ex:

#
# soa
#
.salesteamautomation.com:${ip}:${name}.salesteamautomation.com:3600::lo
.salesteamautomation.com:${peer#*:}:${peer%:*}.salesteamautomation.com:3600::lo

.10.in-addr.arpa:${ip}:${name}.salesteamautomation.com:3600::lo
.10.in-addr.arpa:${peer#*:}:${peer%:*}.salesteamautomation.com:3600::lo

#
# a
#
EOF
(cd "${filename%/*}" && make) || exit 1

filename="etc/fstab"
echo "--- ${filename} (append)"
cat <<EOF>>"/${filename}"

localhost:/${volume}	/var/tinydns/root	glusterfs	_netdev		0 0
EOF

dirname="var/tinydns/root"
echo "--- ${dirname} (mount)"
mv "/${dirname}" "/${dirname}.bak" || exit 1
mkdir -p "/${dirname}"
mount "/${dirname}" || exit 1
rsync -au "/${dirname}.bak/" "/${dirname}/" || exit 1

dirname="var/tinydns"
linkname="service/tinydns"
echo "--- ${linkname} -> ${dirname} (softlink)"
ln -s "/${dirname}/" "/${linkname}" || exit 1

dirname="usr/local/lib64/ns_updater"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="usr/local/lib64/ns_updater/index.php"
echo "--- ${filename} (replacee)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/init.d/ns-updater"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
chmod 755 "/${filename}" || exit 1

/${filename} start || exit 1

rc-update add ${filename##*/} default

filename="etc/nagios/nrpe.cfg"
echo "--- ${filename} (modify)"
sed -i -r \
-e "s|%HOSTNAME_PREFIX%|${hostname_prefix}|"
"/${filename}"

/etc/init.d/nrpe restart || exit 1

filename="etc/ganglia/gmond.conf"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+name\s+\=\s+)\".*\"|\1\"Name Server\"|" \
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+owner\s+\=\s+)\".*\"|\1\"InsideSales\.com, Inc\.\"|" \
-e "\|^udp_send_channel\s+\{$|,\|^\}$|s|(\s+)(mcast_join\s+\=\s+.*)|\1#\2\n\1host \= ${name}|" \
-e "\|^udp_recv_channel\s+\{$|,\|^\}$|s|(\s+)(mcast_join\s+\=\s+.*)|\1#\2|" \
-e "\|^udp_recv_channel\s+\{$|,\|^\}$|s|(\s+)(bind\s+\=\s+.*)|\1#\2|" \
"/${filename}"

/etc/init.d/gmond start || exit 1

rc-update add gmond default

ln -s /var/qmail/supervise/qmail-send/ /service/qmail-send || exit 1
