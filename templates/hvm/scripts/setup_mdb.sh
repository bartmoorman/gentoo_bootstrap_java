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
	echo "Usage: ${BASH_SOURCE[0]} -p peer_name:peer_ip[,peer_name:peer_ip,...] -b bucket_name"
	exit 1
fi

name="$(hostname)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="usr/local/bin/encrypt_decrypt"
functions_file="$(mktemp)"
curl -sf -o "${functions_file}" "${scripts}/${filename}" || exit 1
source "${functions_file}"

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

filename="var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
dev-db/mongodb
sys-fs/lvm2
sys-fs/s3fs
EOF

filename="etc/portage/package.use/lvm2"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
sys-fs/lvm2 -thin
EOF

dirname="etc/portage/package.keywords"
echo "--- $dirname (create)"
mkdir -p "/${dirname}"

filename="etc/portage/package.keywords/mongodb"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-db/mongodb
app-admin/mongo-tools
dev-util/boost-build
dev-libs/boost
EOF

emerge -uDN @system @world || exit 1

filename="etc/mongodb.conf"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^(\s+)(bindIp:.*)|\1#\2\n\1http:\n\1\1enabled: true\n\1\1RESTInterfaceEnabled: true|" \
-e "s|^(\s+)#(ssl:)|\1\2|" \
-e "s|^(\s+)#(\s+mode: disabled)|\1\2|" \
-e "s|^#(security:)|\1|" \
-e "s|^(\s+)#(keyFile:)|\1\2 \"/etc/ssl/mongodb-keyfile\"|" \
-e "s|^#(replication:)|\1|" \
-e "s|^(\s+)#(replSetName:)|\1\2 \"prod0\"|" \
"/${filename}" || exit 1

user="mongodb"
type="keyfile"
echo "-- ${user} ${type} (decrypt)"
declare "${user}_${type}=$(decrypt_user_text "${type}" "${user}")"

filename="etc/ssl/mongodb-keyfile"
echo "--- ${filename} (create)"
cat <<EOF>"/${filename}"
${mongodb_keyfile}
EOF
chmod 600 "/${filename}" || exit 1
chown mongodb: "/${filename}" || exit 1

pvcreate /dev/xvd[fg] || exit 1
vgcreate vg0 /dev/xvd[fg] || exit 1
lvcreate -l 100%VG -n lvol0 vg0 || exit 1
mkfs.ext4 /dev/vg0/lvol0 || exit 1

filename="etc/fstab"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"

/dev/vg0/lvol0	/var/lib/mongodb	ext4		noatime		0 0
EOF

dirname="var/lib/mongodb"
echo "--- ${dirname} (mount)"
mv "/${dirname}" "/${dirname}.bak" || exit 1
mkdir -p "/${dirname}"
mount "/${dirname}" || exit 1
rsync -a "/${dirname}.bak/" "/${dirname}/" || exit 1

counter=0
sleep=30
timeout=1800

/etc/init.d/mongodb start || exit 1

rc-update add mongodb default

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
		mongo --host ${lpeers[peer]%:*} <<'EOF'&>/dev/null
{ping:1}
EOF
		if [ $? -eq 0 ]; then
			echo -n "${lpeers[peer]%:*}..."
			unset lpeers[peer]
		fi
	done

	echo -n "."
	sleep ${sleep}
	counter=$(bc <<< "${counter} + ${sleep}")
done

echo "connected! :)"

user="bmoorman"
app="mongo"
type="pwd"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="ecall"
app="mongo"
type="pwd"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

echo -n "Sleeping..."
sleep $(bc <<< "${RANDOM} % 30")
echo "done! :)"

mongo <<'EOF'
rs.status()
EOF

if [ $? -eq 0 ]; then
	mongo <<EOF
rs.initiate()
use admin
db.createUser({"user":"bmoorman","pwd":"${bmoorman_mongo_pwd}","roles":[{"role":"root","db":"admin"}]})
EOF

	for peer in "${peers[@]}"; do
		mongo <<EOF
use admin
db.auth("bmoorman","${bmoorman_mongodb_pwd}")
rs.add("${peer%:*}")
EOF
	done

	mongo <<'EOF'
use admin
db.auth("bmoorman","${bmoorman_mongodb_pwd}")
db.createUser({"user":"ecall","pwd":"${ecall_mongo_pwd}","roles":[{"role":"root","db":"admin"}]})
EOF
fi
