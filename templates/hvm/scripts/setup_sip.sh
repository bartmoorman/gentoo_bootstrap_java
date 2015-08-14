#!/bin/bash
while getopts "p:b:" OPTNAME; do
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
	esac
done

if [ ${#peers[0]} -eq 0 -o -z "${bucket_name}" ]; then
	echo "Usage: ${BASH_SOURCE[0]} -p peer_name:peer_ip[,peer_name:peer_ip,...] -b files_bucket_name"
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
-e "\|\[gentoo\]|,\|^$|s|^(sync\-uri\s+\=\s+rsync\://).*|\1eu1iec1systems1/gentoo\-portage|" \
"/${filename}"

emerge -q --sync

filename="var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
app-shells/rssh
media-sound/sox
net-misc/asterisk
sys-cluster/glusterfs
sys-fs/s3fs
EOF

filename="etc/portage/package.use/asterisk"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
net-misc/asterisk lua
EOF

filename="etc/portage/package.use/sox"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
media-sound/sox mad
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

emerge -uDN @system @world || exit 1

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
sleep=$(bc <<< "${RANDOM} % 60")
timeout=1800
volume="vmprompts"

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
	gluster volume set ${volume} auth.allow 127.*,10.12.*
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
-e "s|^#(allowrsync)|\1|" \
"/${filename}" || exit 1

usermod -s /usr/bin/rssh asterisk || exit 1

dirname="var/lib/asterisk/.ssh"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="var/lib/asterisk/.ssh/authorized_keys"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "/${scripts}/keys/asterisk" || exit 1

curl -sf "http://eu1iec1ns1:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || curl -sf "http://eu1iec1ns2:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || exit 1
