#!/bin/bash
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
dev-lang/ruby
dev-libs/libmemcached
dev-php/pear
dev-vcs/git
net-libs/libssh2
EOF

filename="etc/portage/package.use/libmemcachd"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-libs/libmemcached sasl
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
