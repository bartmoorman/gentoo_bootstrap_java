#!/bin/bash
ip="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="/var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"
dev-db/mongodb
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

emerge -uDN @world
