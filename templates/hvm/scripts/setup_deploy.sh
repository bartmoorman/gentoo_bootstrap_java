#!/bin/bash
ip="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
name="$(hostname)"
iam_role="$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

dirname="etc/portage/repos.conf"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/portage/repos.conf/gentoo.conf"
echo "--- ${filename} (replace)"
cp "/usr/share/portage/config/repos.conf" "/${filename}" || exit 1
sed -i -r \
-e "\|\[gentoo\]|,\|^$|s|^(sync-uri\s+=\s+rsync://).*|\1eu1iec1systems1/gentoo-portage|" \
"/${filename}"

emerge -q --sync

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

curl -sf "http://eu1iec1ns1:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || curl -sf "http://eu1iec1ns2:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || exit 1
