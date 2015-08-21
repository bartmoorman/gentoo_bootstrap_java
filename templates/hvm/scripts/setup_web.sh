#!/bin/bash
while getopts "b:h:e:" OPTNAME; do
	case $OPTNAME in
		b)
			echo "Bucket Name: ${OPTARG}"
			bucket_name="${OPTARG}"
			;;
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

if [ -z "${bucket_name}" ]; then
	echo "Usage: ${BASH_SOURCE[0]} -b files_bucket_name [-h hostname_prefix] [-e environment_suffix]"
	exit 1
fi

ip="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
name="$(hostname)"
iam_role="$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="usr/local/bin/encrypt_decrypt"
functions_file="$(mktemp)"
curl -sf -o "${functions_file}" "${scripts}/${filename}" || exit 1
source "${functions_file}"

dirname="etc/portage/repos.conf"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/portage/repos.conf/gentoo.conf"
echo "--- ${filename} (replace)"
cp "/usr/share/portage/config/repos.conf" "/${filename}" || exit 1
sed -i -r \
-e "\|^\[gentoo\]$|,\|^$|s|^(sync\-uri\s+\=\s+rsync\://).*|\1${hostname_prefix}systems1/gentoo\-portage|" \
"/${filename}"

emerge -q --sync || exit 1

filename="var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
dev-libs/libmemcached
dev-php/PEAR-Mail
dev-php/PEAR-Mail_Mime
dev-php/PEAR-Spreadsheet_Excel_Writer
dev-php/pear
dev-php/smarty
dev-qt/qtwebkit
net-libs/libssh2
media-video/ffmpeg
media-sound/sox
sys-apps/miscfiles
sys-fs/s3fs
www-apache/mod_fcgid
www-servers/apache
EOF

filename="etc/portage/package.use/apache"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
www-servers/apache apache2_modules_log_forensic
EOF

filename="etc/portage/package.use/libmemcached"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-libs/libmemcached sasl
EOF

filename="etc/portage/package.use/php"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-lang/php apache2 bcmath calendar cgi curl exif ftp gd inifile intl pcntl pdo sharedmem snmp soap sockets spell sysvipc truetype xmlreader xmlrpc xmlwriter zip
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

filename="etc/portage/package.keywords/libmemcached"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-libs/libmemcached
EOF

mirrorselect -s5 || exit 1

emerge -uDN @system @world || emerge --resume || exit 1

filename="etc/fstab"
echo "--- ${filename} (append)"
cat <<EOF>>"/${filename}"

s3fs#${bucket_name}	/mnt/s3		fuse	_netdev,allow_other,url=https://s3.amazonaws.com,iam_role=${iam_role}	0 0
EOF

dirname="mnt/s3"
echo "--- ${dirname} (mount)"
mkdir -p "/${dirname}"
mount "/${dirname}" || exit 1

dirname="var/www"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

dirname="mnt/s3/repository/sta_files"
linkname="var/www/sta_files"
echo "--- ${linkname} -> ${dirname} (softlink)"
ln -s "/${dirname}/" "/${linkname}" || exit 1

dirname="mnt/s3/repository/sta_files_recycle_bin"
linkname="var/www/sta_files_recycle_bin"
echo "--- ${linkname} -> ${dirname} (softlink)"
ln -s "/${dirname}/" "/${linkname}" || exit 1

dirname="mnt/s3/repository/sta2_files"
linkname="var/www/sta2_files"
echo "--- ${linkname} -> ${dirname} (softlink)"
ln -s "/${dirname}/" "/${linkname}" || exit 1

dirname="mnt/s3/repository/sta2_files_recycle_bin"
linkname="var/www/sta2_files_recycle_bin"
echo "--- ${linkname} -> ${dirname} (softlink)"
ln -s "/${dirname}/" "/${linkname}" || exit 1

filename="etc/php/apache2-php5.6/php.ini"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^(short_open_tag\s+\=\s+).*|\1On|" \
-e "s|^(expose_php\s+\=\s+).*|\1Off|" \
-e "s|^(error_reporting\s+\=\s+).*|\1E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED|" \
-e "s|^(display_errors\s+\=\s+).*|\1Off|" \
-e "s|^(display_startup_errors\s+\=\s+).*|\1Off|" \
-e "s|^(track_errors\s+\=\s+).*|\1Off|" \
-e "s|^;(date\.timezone\s+\=).*|\1 America/Denver|" \
"/${filename}" || exit 1

filename="etc/php/cgi-php5.6/php.ini"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^(short_open_tag\s+\=\s+).*|\1On|" \
-e "s|^(expose_php\s+\=\s+).*|\1Off|" \
-e "s|^(error_reporting\s+\=\s+).*|\1E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED|" \
-e "s|^(display_errors\s+\=\s+).*|\1Off|" \
-e "s|^(display_startup_errors\s+\=\s+).*|\1Off|" \
-e "s|^(track_errors\s+\=\s+).*|\1Off|" \
-e "s|^;(date\.timezone\s+\=).*|\1 America/Denver|" \
"/${filename}" || exit 1

dirname="usr/share/php/smarty"
linkname="usr/share/php/Smarty"
echo "--- ${linkname} -> ${dirname} (softlink)"
ln -s "/${dirname}/" "/${linkname}" || exit 1

filename="etc/conf.d/apache2"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^APACHE2_OPTS\=\"(.*)\"$|APACHE2_OPTS\=\"\-D INFO \-D SSL \-D LANGUAGE \-D PHP5 \-D FCGID\"|" \
"/${filename}" || exit 1

filename="etc/apache2/modules.d/00_default_settings.conf"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^(Timeout\s+).*|\130|" \
-e "s|^(KeepAliveTimeout\s+).*|\13|" \
-e "s|^(ServerSignature\s+).*|\1Off|" \
"/${filename}" || exit 1

log_config_file="$(mktemp)"
cat <<'EOF'>"${log_config_file}"
LogFormat "%P %{Host}i %h %{%Y-%m-%d %H:%M:%S %z}t %m %U %H %>s %B %D" stats
LogFormat "%P %{Host}i %h %{%Y-%m-%d %H:%M:%S %z}t %{User-Agent}i" agents
LogFormat "%>s %h" status

ErrorLog "|php /usr/local/lib64/apache2/error.php"

CustomLog "|php /usr/local/lib64/apache2/stats.php" stats
CustomLog "|php /usr/local/lib64/apache2/agents.php" agents
CustomLog "|php /usr/local/lib64/apache2/status.php" status

ForensicLog /var/log/apache2/forensic_log

EOF

filename="etc/apache2/modules.d/00_mod_log_config.conf"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^(LogFormat)|#\1|" \
-e "s|^(CustomLog)|#\1|" \
-e "\|log_config_module|r ${log_config_file}" \
"/${filename}" || exit 1

filename="etc/apache2/modules.d/00_mpm.conf"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "\|prefork MPM|i ServerLimit 1024\n" \
-e "\|^\<IfModule mpm_prefork_module\>$|,\|^\</IfModule\>$|s|^(\s+MaxClients\s+).*|\11024|" \
"/${filename}" || exit 1

filename="etc/apache2/vhosts.d/01_isdc_lmp_vhost.conf"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/apache2/vhosts.d/02_isdc_other_vhost.conf"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

for d in $(grep -h ^Include /etc/apache2/vhosts.d/01_isdc_lmp_vhost.conf /etc/apache2/vhosts.d/02_isdc_other_vhost.conf | cut -d' ' -f2); do
	dirname="${d%/*}"
	echo "--- ${dirname} (create)"
	mkdir -p "${dirname}"

	filename="${d}"
	echo "--- ${filename} (create)"
	touch "${filename}" || exit 1
done

dirname="usr/local/lib64/apache2/include"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="usr/local/lib64/apache2/agents.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
chmod 755 "/${filename}" || exit 1

filename="usr/local/lib64/apache2/error.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
chmod 755 "/${filename}" || exit 1

filename="usr/local/lib64/apache2/stats.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
chmod 755 "/${filename}" || exit 1

filename="usr/local/lib64/apache2/status.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
chmod 755 "/${filename}" || exit 1

filename="usr/local/lib64/apache2/include/settings.inc"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

user="stats"
app="mysql"
type="auth"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

sed -i -r \
-e "s|%STATS_AUTH%|${stats_mysql_auth}|" \
"/${filename}" || exit 1

/etc/init.d/apache2 start || exit 1

rc-update add apache2 default

for i in memcache memcached mongo oauth ssh2-beta; do
	yes "" | pecl install "${i}" > /dev/null || exit 1

	dirname="etc/php"
	echo "--- ${dirname} (processing)"

	for j in $(ls "/${dirname}"); do
		filename="${dirname}/${j}/ext/${i%-*}.ini"
		echo "--- ${filename} (replace)"
		cat <<EOF>"/${filename}"
extension=${i%-*}.so
EOF

		linkname="${dirname}/${j}/ext-active/${i%-*}.ini"
		echo "--- ${linkname} -> ${filename} (softlink)"
		ln -s "/${filename}" "/${linkname}" || exit 1
	done
done

filename="usr/local/bin/wkhtmltopdf"
echo "--- ${filename} (replace)"
wkhtmltopdf_file="$(mktemp)"
curl -sf -o "${wkhtmltopdf_file}" "http://download.gna.org/wkhtmltopdf/obsolete/linux/wkhtmltopdf-0.11.0_rc1-static-amd64.tar.bz2" || exit 1
tar xjf "${wkhtmltopdf_file}" -C "/${filename%/*}" || exit 1
mv "/${filename}-amd64" "/${filename}" || exit 1

linkname="usr/bin/wkhtmltopdf"
echo "--- ${linkname} -> ${filename} (softlink)"
ln -s "/${filename}" "/${linkname}" || exit 1

filename="usr/local/bin/wkhtmltoimage"
echo "--- ${filename} (replace)"
wkhtmltoimage_file="$(mktemp)"
curl -sf -o "${wkhtmltoimage_file}" "http://download.gna.org/wkhtmltopdf/obsolete/linux/wkhtmltoimage-0.11.0_rc1-static-amd64.tar.bz2" || exit 1
tar xjf "${wkhtmltoimage_file}" -C "/${filename%/*}" || exit 1
mv "/${filename}-amd64" "/${filename}" || exit 1

linkname="usr/bin/wkhtmltoimage"
echo "--- ${linkname} -> ${filename} (softlink)"
ln -s "/${filename}" "/${linkname}" || exit 1

filename="etc/ganglia/gmond.conf"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+name\s+\=\s+)\".*\"|\1\"Web\"|" \
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+owner\s+\=\s+)\".*\"|\1\"InsideSales\.com, Inc\.\"|" \
-e "\|^udp_send_channel\s+\{$|,\|^\}$|s|(\s+)(mcast_join\s+\=\s+.*)|\1#\2\n\1host \= ${name}|" \
-e "\|^udp_recv_channel\s+\{$|,\|^\}$|s|(\s+)(mcast_join\s+\=\s+.*)|\1#\2|" \
-e "\|^udp_recv_channel\s+\{$|,\|^\}$|s|(\s+)(bind\s+\=\s+.*)|\1#\2|" \
"/${filename}"

/etc/init.d/gmond start || exit 1

rc-upddate add gmond default

curl -sf "http://${hostname_prefix}ns1:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || curl -sf "http://${hostname_prefix}ns2:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || exit 1
