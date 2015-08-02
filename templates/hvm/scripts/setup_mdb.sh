#!/bin/bash
while getopts "i:j:n:o:" OPTNAME; do
	case $OPTNAME in
		i)
			echo "Peer1 IP: ${OPTARG}"
			peer1_ip="${OPTARG}"
			;;
		j)
			echo "Peer2 ID: ${OPTARG}"
			peer2_ip="${OPTARG}"
			;;
		n)
			echo "Peer1 Name: ${OPTARG}"
			peer1_name="${OPTARG}"
			;;
		o)
			echo "Peer2 Name: ${OPTARG}"
			peer2_name="${OPTARG}"
			;;
	esac
done

if [ -z "${peer1_ip}" -o -z "${peer1_name}" -o -z "${peer2_ip}" -o -z "${peer2_name}"]; then
	echo "Usage: ${BASH_SOURCE[0]} -n peer1_name -i peer1_ip -o peer2_name -j peer2_ip"
	exit 1
fi

name="$(hostname)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="/tmp/encrypt_decrypt_text"
echo "--- ${filename} (replace)"
curl -sf -o "${filename}" "${scripts}${filename}" || exit 1
source "${filename}"

filename="/etc/hosts"
echo "--- ${filename} (append)"
cat <<EOF>>"${filename}"

${peer1_ip}	${peer1_name}.salesteamautomation.com ${peer1_name}
${peer2_ip}	${peer2_name}.salesteamautomation.com ${peer2_name}
EOF

filename="/var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"
dev-db/mongodb
sys-fs/lvm2
sys-fs/s3fs
EOF

filename="/etc/portage/package.use/lvm2"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
sys-fs/lvm2 -thin
EOF

dirname="/etc/portage/package.keywords"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

filename="/etc/portage/package.keywords/mongodb"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
dev-db/mongodb
app-admin/mongo-tools
EOF

emerge -uDN @world || exit 1

filename="/etc/mongodb.conf"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s|^(\s+)(bindIp:.*)|\1#\2\n\1http:\n\1\1enabled: true\n\1\1RESTInterfaceEnabled: true|" \
-e "s|^(\s+)#(ssl:)|\1\2|" \
-e "s|^(\s+)#(\s+mode: disabled)|\1\2|" \
-e "s|^#(security:)|\1|" \
-e "s|^(\s+)#(keyFile:)|\1\2 \"/etc/ssl/mongodb-keyfile\"|" \
-e "s|^#(replication:)|\1|" \
-e "s|^(\s+)#(replSetName:)|\1\2 \"prod0\"|" \
"${filename}" || exit 1

user="mongodb"
type="keyfile"
echo "-- ${user} ${type} (decrypt)"
declare "${user}_${type}=$(decrypt_user_text "${type}" "${user}")"

filename="/etc/ssl/mongodb-keyfile"
echo "--- ${filename} (create)"
cat <<EOF>"${filename}"
${mongodb_keyfile}
EOF
chmod 600 "${filename}"
chown mongodb: "${filename}"

pvcreate /dev/xvd[fg] || exit 1
vgcreate vg0 /dev/xvd[fg] || exit 1
lvcreate -l 100%VG -n lvol0 vg0 || exit 1
mkfs.ext4 /dev/vg0/lvol0 || exit 1

filename="/etc/fstab"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"

/dev/vg0/lvol0	/var/lib/mongodb	ext4		noatime		0 0
EOF

dirname="/var/lib/mongodb"
echo "--- ${dirname} (mount)"
mv "${dirname}" "${dirname}.bak" || exit 1
mkdir -p "${dirname}"
mount "${dirname}" || exit 1
rsync -a "${dirname}.bak/" "${dirname}/" || exit 1

/etc/init.d/mongodb start || exit 1

rc-update add mongodb default

mongo <<'EOF'
rs.add("${name}")
rs.add("${peer1_name}")
rs.add("${peer2_name}")
rs.status()
EOF
