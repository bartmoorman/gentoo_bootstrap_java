#!/bin/bash
while getopts ":h:e:" OPTNAME; do
	case $OPTNAME in
		h)
			echo "Hostname Prefix: ${OPTARG}"
			hostname_prefix="${OPTARG}"
			;;
		e)
			echo "Environment Suffix: ${OPTARG}"
			environment_suffix="${OPTARG}"
			;;
	esac
done

if [ ]; then
	echo "Usage: ${BASH_SOURCE[0]} [-h hostname_prefix] [-e environment_suffix]"
	exit 1
fi

ip="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
name="$(hostname)"
iam_role="$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

declare "$(dhcpcd -4T eth0 | grep ^new_domain_name_servers | tr -d \')"

svc -d /service/dnscache || exit 1

filename="var/dnscache/root/servers/@"
echo "--- ${filename} (replace)"
tr ' ' '\n' <<< "${new_domain_name_servers}" > "/${filename}"

svc -u /service/dnscache || exit 1

emerge -q --sync || exit 1

dirname="etc/portage/repos.conf"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/portage/repos.conf/gentoo.conf"
echo "--- ${filename} (replace)"
cp "/usr/share/portage/config/repos.conf" "/${filename}" || exit 1
sed -i -r \
-e "\|^\[gentoo\]$|,\|^$|s|^(sync\-uri\s+\=\s+rsync\://).*|\1${hostname_prefix}systems1/gentoo\-portage|" \
"/${filename}"

filename="var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
app-shells/rssh
dev-db/mongodb
dev-db/mysql
dev-db/mytop
dev-lang/go
dev-lang/ruby:2.0
dev-libs/libmemcached
dev-php/PEAR-Mail
dev-php/PEAR-Mail_Mime
dev-php/PEAR-Spreadsheet_Excel_Writer
dev-php/pear
dev-python/mysql-python
dev-qt/qtwebkit:4
dev-vcs/git
media-video/ffmpeg
media-sound/sox
net-analyzer/nagios
net-firewall/iptables
net-fs/s3fs
net-libs/libssh2
net-misc/asterisk
net-misc/memcached
net-misc/rabbitmq-server
sys-apps/miscfiles
sys-apps/pv
sys-cluster/glusterfs
sys-fs/lvm2
sys-process/at
www-apache/mod_fcgid
www-servers/apache
www-servers/tomcat
EOF

filename="etc/portage/package.use/apache"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
www-servers/apache apache2_modules_log_forensic
EOF

filename="etc/portage/package.use/gd"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
media-libs/gd jpeg png
EOF

filename="etc/portage/package.use/ganglia"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
sys-cluster/ganglia minimal python
EOF

filename="etc/portage/package.use/icedtea-bin"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-java/icedtea-bin -X -cups
EOF

filename="etc/portage/package.use/libmemcached"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-libs/libmemcached sasl
EOF

filename="etc/portage/package.use/lvm2"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
sys-fs/lvm2 -thin
EOF

filename="etc/portage/package.use/mysql"
echo "--- ${filename} (modify)"
sed -i -r \
-e "s|minimal|extraengine profiling|" \
"/${filename}" || exit 1

filename="etc/portage/package.use/nagios"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
net-analyzer/nagios-core apache2
EOF

filename="etc/portage/package.use/php"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-lang/php apache2 bcmath calendar cgi curl exif ftp gd inifile intl mysql mysqli pcntl pdo sharedmem snmp soap sockets spell sysvipc truetype xmlreader xmlrpc xmlwriter zip
app-eselect/eselect-php apache2
EOF

filename="etc/portage/package.use/sox"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
media-sound/sox mad
EOF

dirname="etc/portage/package.keywords"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/portage/package.keywords/glusterfs"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
sys-cluster/glusterfs
EOF

filename="etc/portage/package.keywords/libmemcached"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-libs/libmemcached
EOF

filename="etc/portage/package.keywords/mongodb"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-db/mongodb
app-admin/mongo-tools
dev-util/boost-build
dev-libs/boost
EOF

filename="etc/portage/package.keywords/rabbitmq-server"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
net-misc/rabbitmq-server
EOF

filename="etc/portage/package.keywords/rssh"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
app-shells/rssh
EOF

#mirrorselect -D -b10 -s5 || exit 1

dirname="var/tmp/portage"
echo "--- ${dirname} (mount)"
mkdir -p "/${dirname}"
chmod 775 "/${dirname}"
chown portage: "/${dirname}"
mount -t tmpfs -o size=16G tmpfs "/${dirname}" || exit 1

emerge -uDNb @system @world || emerge --resume || exit 1

filename="etc/apache2/vhosts.d/01_isdc_bin_vhost.conf"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

/etc/init.d/apache2 start || exit 1

rc-update add apache2 default

nrpe_file="$(mktemp)"
cat <<'EOF'>"${nrpe_file}"

command[check_apache]=/usr/lib64/nagios/plugins/check_procs -c 1:135 -w 5:120 -C apache2 -a /usr/sbin/apache2
EOF

filename="etc/nagios/nrpe.cfg"
echo "--- ${filename} (modify)"
sed -i -r \
-e "\|^command\[check_total_procs\]|r ${nrpe_file}" \
-e "s|%HOSTNAME_PREFIX%|${hostname_prefix}|" \
"/${filename}" || exit 1

/etc/init.d/nrpe restart || exit 1

filename="etc/ganglia/gmond.conf"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+name\s+\=\s+)\".*\"|\1\"Binary\"|" \
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+owner\s+\=\s+)\".*\"|\1\"InsideSales\.com, Inc\.\"|" \
-e "\|^udp_send_channel\s+\{$|,\|^\}$|s|(\s+)(mcast_join\s+\=\s+.*)|\1#\2\n\1host \= ${name}|" \
-e "\|^udp_recv_channel\s+\{$|,\|^\}$|s|(\s+)(mcast_join\s+\=\s+.*)|\1#\2|" \
-e "\|^udp_recv_channel\s+\{$|,\|^\}$|s|(\s+)(bind\s+\=\s+.*)|\1#\2|" \
"/${filename}"

/etc/init.d/gmond start || exit 1

rc-update add gmond default

yes "" | emerge --config mail-mta/netqmail || exit 1

ln -s /var/qmail/supervise/qmail-send/ /service/qmail-send || exit 1

curl -sf "http://${hostname_prefix}ns1:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || curl -sf "http://${hostname_prefix}ns2:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || exit 1

echo "--- SUCCESS :)"
