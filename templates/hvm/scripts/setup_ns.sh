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

if [ "${hostname:(-3)}" == "ns1" ]; then
	peer_name="${hostname::(-3)}ns2"
	peer_ip="10.12.32.10"
elif [ "${hostname:(-3)}" == "ns2" ]; then
	peer_name="${hostname::(-3)}ns1"
	peer_ip="10.12.16.10"
fi

filename="/etc/resolv.conf.head"
echo "--- ${filename} (delete)"
rm "${filename}"

svc -d /service/dnscache

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

svc -u /service/dnscache

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
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
sys-cluster/glusterfs
EOF

emerge -uDN @world

counter=0
sleep=3
timeout=600
volume="tinydns"

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
	gluster volume set ${volume} auth.allow 127.*,10.12.*
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
mkdir -p "${dirname}"
mount "${dirname}"
rsync -a "${dirname}.bak/" "${dirname}"

ln -s /var/tinydns/ /service/tinydns

dirname="/usr/local/lib64/nsupdater"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

filename="/usr/local/lib64/nsupdater/index.php"
echo "--- ${filename} (replacee)"
cat <<'EOF'>"${filename}"
<?php
echo 'hello';
?>
EOF

filename="/etc/init.d/nsupdater"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
#!/sbin/runscript

checkconfig() {
        PIDFILE="${PIDFILE:-/var/run/${SVCNAME}.pid}"
        LOGFILE="${LOGFILE:-/var/log/${SVCNAME}.log}"
        DAEMON="${DAEMON:-/usr/bin/php}"
        DAEMON_IP="${DAEMON_IP:-0.0.0.0}"
        DAEMON_PORT="${DAEMON_PORT:-8053}"
        DAEMON_SCRIPT="${DAEMON_SCRIPT:-/usr/local/lib64/nsupdater/index.php}"
        DAEMON_OPTS="-S ${DAEMON_IP}:${DAEMON_PORT} ${DAEMON_SCRIPT}"
}

start() {
        checkconfig || return 1

        ebegin "Starting ${SVCNAME}"
        start-stop-daemon --start --background --make-pidfile --pidfile ${PIDFILE} --exec ${DAEMON} -- ${DAEMON_OPTS} &>> ${LOGFILE}
        eend $?
}

stop() {
        checkconfig || return 1

        ebegin "Stopping ${SVCNAME}"
        start-stop-daemon --stop --pidfile ${PIDFILE}
        eend $?
}
EOF
chmod 755 "${filename}"

/etc/init.d/nsupdater start

rc-update add nsupdater default
