#!/bin/bash
while getopts ":p:b:h:e:" OPTNAME; do
	case $OPTNAME in
		p)
			echo "Peers: ${OPTARG}"
			peers=(${OPTARG//,/ })
			lpeers=(${OPTARG//,/ })
			;;
		b)
			echo "Bucket Name: ${OPTARG}"
			bucket_name="${OPTARG}"
			;;
		h)
			echo "Hostname Prefix: ${OPTARG}"
			hostname_prefix="${OPTARG}"
			;;
		e)
			echo "Environment Suffix: ${OPTARG}"
			environment_suffix="${OPTARG}"
			;;
	esac
done

if [ ${#peers[0]} -eq 0 -o -z "${bucket_name}" ]; then
	echo "Usage: ${BASH_SOURCE[0]} -p peer_name:peer_ip[,peer_name:peer_ip,...] -b files_bucket_name [-h hostname_prefix] [-e environment_suffix]"
	exit 1
fi

ip="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
name="$(hostname)"
iam_role="$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

n=$'\n'
t=$'\t'

for peer in "${peers[@]}"; do
        hosts+="${n}${peer#*:}${t}${peer%:*}.salesteamautomation.com ${peer%:*}"
done

filename="etc/hosts"
echo "--- ${filename} (append)"
cat <<EOF>>"/${filename}"
${hosts}
EOF

dirname="etc/portage/repos.conf"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/portage/repos.conf/gentoo.conf"
echo "--- ${filename} (replace)"
cp "/usr/share/portage/config/repos.conf" "/${filename}" || exit 1
sed -i -r \
-e "\|^\[gentoo\]$|,\|^$|s|^(sync\-uri\s+\=\s+rsync\://).*|\1${hostname_prefix}systems1/gentoo\-portage|" \
"/${filename}"

emerge -q --sync || exit 1

filename="var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
app-shells/rssh
net-misc/asterisk
sys-cluster/glusterfs
sys-fs/s3fs
EOF

dirname="etc/portage/package.keywords"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/portage/package.keywords/glusterfs"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
sys-cluster/glusterfs
EOF

filename="etc/portage/package.keywords/rssh"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
app-shells/rssh
EOF

mirrorselect -D -c Ireland -R Europe -s5 || exit 1

filename="etc/portage/make.conf"
echo "--- ${filename} (modify)"
sed -i -r \
-e "\|^EMERGE_DEFAULT_OPTS|a PORTAGE_BINHOST\=\"http\://${hostname_prefix}bin1/packages\"" \
"/${filename}" || exit 1

#emerge -uDNg @system @world || emerge --resume || exit 1
emerge -uDN @system @world || emerge --resume || exit 1

filename="etc/fstab"
echo "--- ${filename} (append)"
cat <<EOF>>"/${filename}"

s3fs#${bucket_name}	/mnt/s3		fuse	_netdev,allow_other,url=https://s3.amazonaws.com,iam_role=${iam_role}	0 0
EOF

dirname="mnt/s3"
echo "--- ${dirname} (mount)"
mkdir -p "/${dirname}"
mount "/${dirname}" || exit 1

counter=0
timeout=1800
volume="vmprompts"

part=$(bc <<< "60 / (${#peers[@]} + 1)")
position=0

for peer in "${peers[@]}"; do
	if [ "${ip}" \> "${peer#*:}" ]; then
		position=$(bc <<< "${position} + 1")
	fi
done

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

echo -n "Waiting for ${#peers[@]} peers..."

while [ "${#lpeers[@]}" -gt 0 ]; do
	if [ "${counter}" -ge "${timeout}" ]; then
		echo "failed! :("
		exit 1
	fi

	for peer in "${!lpeers[@]}"; do
		if gluster peer probe ${lpeers[peer]%:*} &> /dev/null; then
			echo -n "${lpeers[peer]%:*}..."
			unset lpeers[peer]
		fi
	done

	echo -n "."
	sleep ${sleep}
	counter=$(bc <<< "${counter} + ${sleep}")
done

echo "connected! :)"

echo -n "Sleeping (${sleep}s)..."
sleep ${sleep}
echo "done! :)"

hosts="${name}:/var/glusterfs/${volume}"

for peer in "${peers[@]}"; do
        hosts+=" ${peer%:*}:/var/glusterfs/${volume}"
done

if ! gluster volume info ${volume} &> /dev/null; then
	echo "--- ${volume} (manage)"
	gluster volume create ${volume} replica $(bc <<< "${#peers[@]} + 1") ${hosts} force || exit 1
	gluster volume set ${volume} auth.allow 127.*,10.*
	gluster volume start ${volume} || exit 1
fi

filename="etc/fstab"
echo "--- ${filename} (append)"
cat <<EOF>>"/${filename}"

localhost:/${volume}	/var/lib/asterisk/sounds/vmprompts	glusterfs	_netdev		0 0
EOF

dirname="var/lib/asterisk/sounds/vmprompts"
echo "--- ${dirname} (mount)"
mkdir -p "/${dirname}"
mount "/${dirname}" || exit 1

filename="etc/rssh.conf"
echo "--- ${filename} (modify)"
cp "/${filename}.default" "/${filename}"
sed -r -i \
-e "s|^#(allowrsync)$|\1|" \
"/${filename}" || exit 1

usermod -s /usr/bin/rssh asterisk || exit 1

dirname="var/lib/asterisk/.ssh"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="var/lib/asterisk/.ssh/authorized_keys"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/keys/asterisk" || exit 1

/etc/init.d/asterisk start || exit 1

rc-update add asterisk default

nrpe_file="$(mktemp)"
cat <<'EOF'>"${nrpe_file}"

command[check_cpu]=/usr/lib64/nagios/plugins/custom/check_cpu -w 50 -c 40
EOF

filename="etc/nagios/nrpe.cfg"
echo "--- ${filename} (modify)"
sed -i -r \
-e "\|^command\[check_total_procs\]|r ${nrpe_file}" \
-e "s|%HOSTNAME_PREFIX%|${hostname_prefix}|" \
"/${filename}" || exit 1

/etc/init.d/nrpe restart || exit 1

dirname="usr/lib64/nagios/plugins/custom"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="usr/lib64/nagios/plugins/custom/check_cpu"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
chmod 755 "/${filename}" || exit 1

filename="var/spool/cron/crontabs/root"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"

* * * * *	/usr/lib64/sa/sa1 5 12
55 23 * * *	/usr/lib64/sa/sa2
EOF
touch "/${filename%/*}" || exit 1

filename="etc/ganglia/gmond.conf"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+name\s+\=\s+)\".*\"|\1\"Dialer\"|" \
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+owner\s+\=\s+)\".*\"|\1\"InsideSales\.com, Inc\.\"|" \
-e "\|^udp_send_channel\s+\{$|,\|^\}$|s|(\s+)(mcast_join\s+\=\s+.*)|\1#\2\n\1host \= ${name}|" \
-e "\|^udp_recv_channel\s+\{$|,\|^\}$|s|(\s+)(mcast_join\s+\=\s+.*)|\1#\2|" \
-e "\|^udp_recv_channel\s+\{$|,\|^\}$|s|(\s+)(bind\s+\=\s+.*)|\1#\2|" \
"/${filename}"

/etc/init.d/gmond start || exit 1

rc-update add gmond default

ln -s /var/qmail/supervise/qmail-send/ /service/qmail-send || exit 1

curl -sf "http://${hostname_prefix}ns1:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || curl -sf "http://${hostname_prefix}ns2:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || exit 1
