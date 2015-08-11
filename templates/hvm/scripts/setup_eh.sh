#!/bin/bash
while getopts "b:" OPTNAME; do
	case $OPTNAME in
		b)
			echo "Bucket Name: ${OPTARG}"
			bucket_name="${OPTARG}"
			;;
	esac
done

if [ ]; then
	echo "Usage: ${BASH_SOURCE[0]} -b bucket_name"
	exit 1
fi

scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
dev-libs/libmemcached
dev-php/pear
net-libs/libssh2
sys-fs/s3fs
EOF

filename="etc/portage/package.use/libmemcachd"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-libs/libmemcached sasl
EOF

filename="etc/portage/package.use/php"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-lang/php bcmath calendar curl exif ftp gd inifile intl pcntl pdo sharedmem snmp soap sockets spell sysvipc truetype xmlreader xmlrpc xmlwriter zip
EOF

dirname="etc/portage/package.keywords"
echo "--- $dirname (create)"
mkdir -p "/${dirname}"

filename="etc/portage/package.keywords/libmemcachd"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-libs/libmemcached
EOF

emerge -uDN @system @world || exit 1
