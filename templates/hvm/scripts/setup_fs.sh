#!/bin/bash
hostname="$(hostname)"
if [ "${hostname:(-3)}" == "fs1" ]; then
        peer_name="${hostname::(-3)}fs2"
elif [ "${hostname:(-3)}" == "fs2" ]; then
        peer_name="${hostname::(-3)}fs1"
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

filename="/var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"
sys-cluster/glusterfs
sys-fs/lvm2
EOF

filename="/etc/portage/package.use/lvm2"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
sys-fs/lvm2 -thin
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
volume="nfs"

dirname="/var/glusterfs/${volume}"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

/etc/init.d/glusterd start

rc-update add glusterd default

pvcreate /dev/xvd[fg]
vgcreate vg0 /dev/xvd[fg]
lvcreate -l 100%VG -n lvol0 vg0
mkfs.ext4 /dev/vg0/lvol0

filename="/etc/fstab"
echo "--- ${filename} (append)"
cat <<EOF>>"${filename}"

/dev/vg0/lvol0		/var/glusterfs/${volume}	ext4		noatime		0 0
EOF

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
