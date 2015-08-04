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

if [ ${#peers[@]} -eq 0 ]; then
	echo "Usage: ${BASH_SOURCE[0]} -p peer_name:peer_ip[,peer_name:peer_ip,...]"
	exit 1
fi

name="$(hostname)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="/tmp/encrypt_decrypt_text"
echo "--- ${filename} (replace)"
curl -sf -o "${filename}" "${scripts}${filename}" || exit 1
source "${filename}"

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

emerge -uDN @system @world || exit 1

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
