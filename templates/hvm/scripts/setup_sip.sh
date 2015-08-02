#!/bin/bash
while getopts "p:" OPTNAME; do
	case $OPTNAME in
		p)
			echo "Peers: ${OPTARG}"
			peers=(${OPTARG//,/ })
			lpeers=(${OPTARG//,/ })
			;;
	esac
done

name="$(hostname)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

n=$'\n'
t=$'\t'

for peer in "${peers[@]}"; do
        hosts+="${n}${peer#*:}${t}${peer%:*}.salesteamautomation.com ${peer%:*}"
done

filename="/etc/hosts"
echo "--- ${filename} (append)"
cat <<EOF>>"${filename}"
${hosts}
EOF

filename="/var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"
app-shells/rssh
net-misc/asterisk
sys-cluster/glusterfs
sys-fs/s3fs
EOF

filename="/etc/portage/package.use/asterisk"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
net-misc/asterisk lua
EOF

dirname="/etc/portage/package.keywords"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

filename="/etc/portage/package.keywords/glusterfs"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
sys-cluster/glusterfs
EOF

filename="/etc/portage/package.keywords/rssh"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
app-shells/rssh
EOF

emerge -uDN @world || exit 1

counter=0
sleep=30
timeout=1800
volume="vmprompts"

dirname="/var/glusterfs/${volume}"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

/etc/init.d/glusterd start || exit 1

rc-update add glusterd default

echo -n "Sleeping..."
sleep $(bc <<< "${RANDOM} % 30")
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

echo -n "Sleeping..."
sleep $(bc <<< "${RANDOM} % 30")
echo "done! :)"

hosts="${name}:/var/glusterfs/${volume}"

for peer in "${peers[@]}"; do
        hosts+=" ${peer%:*}:/var/glusterfs/${volume}"
done

if ! gluster volume info ${volume} &> /dev/null; then
	echo "--- $volume (manage)"
	gluster volume create ${volume} replica $(bc <<< "${#peers[@]} + 1") ${hosts} force || exit 1
	gluster volume set ${volume} auth.allow 127.*,10.12.*
	gluster volume start ${volume} || exit 1
fi

filename="/etc/fstab"
echo "--- ${filename} (append)"
cat <<EOF>>"${filename}"

localhost:/${volume}	/var/lib/asterisk/sounds/vmprompts	glusterfs	_netdev		0 0
EOF

dirname="/var/lib/asterisk/sounds/vmprompts"
echo "--- $dirname (mount)"
mkdir -p "${dirname}"
mount "${dirname}" || exit 1

filename="/etc/rssh.conf"
echo "--- ${filename} (modify)"
cp "${filename}.default" "${filename}"
sed -r -i \
-e "s|^#(allowrsync)|\1|" \
"${filename}"

usermod -s /usr/bin/rssh asterisk

dirname="/var/lib/asterisk/.ssh"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

filename="/var/lib/asterisk/.ssh/authorized_keys"
echo "--- ${filename} (replace)"
curl -sf -o "${filename}" "${scripts}/keys/asterisk" || exit 1
