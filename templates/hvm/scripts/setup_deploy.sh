#!/bin/bash
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
dev-lang/ruby:2.0
dev-libs/libmemcached
dev-php/pear
dev-vcs/git
net-libs/libssh2
EOF

filename="etc/portage/package.use/libmemcached"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-libs/libmemcached sasl
EOF

dirname="etc/portage/package.keywords"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/portage/package.keywords/libmemcached"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-libs/libmemcached
EOF

emerge -uDN @system @world || exit 1

filename="usr/local/bin/composer"
echo "--- ${filename} (replace)"
composer_file="$(mktemp)"
curl -sf -o "${composer_file}" "https://getcomposer.org/installer" || exit 1
php "${composer_file}" -- --install-dir="/${filename%/*}" --filename="${filename##*/}" || exit 1
