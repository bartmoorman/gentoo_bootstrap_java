#!/bin/bash
name="$(hostname)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

while getopts "p:" OPTNAME; do
	case $OPTNAME in
		p)
			echo "Peers: ${OPTARG}"
			peers=(${p//,/ })
			lpeers=(${p//,/ })
			;;
	esac
done

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
net-misc/asterisk
sys-cluster/glusterfs
sys-fs/s3fs
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
	gluster volume create ${volume} replica ${#peers[@]} ${hosts} force || exit 1
	gluster volume set ${volume} auth.allow 127.*,10.12.*
	gluster volume start ${volume} || exit 1
fi
