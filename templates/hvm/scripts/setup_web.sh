#!/bin/bash
while getopts "b:" OPTNAME; do
	case $OPTNAME in
		b)
			echo "Bucket Name: ${OPTARG}"
			bucket_name="${OPTARG}"
			;;
	esac
done

scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="/tmp/encrypt_decrypt_text"
echo "--- ${filename} (replace)"
curl -sf -o "${filename}" "${scripts}${filename}" || exit 1
source "${filename}"

filename="/var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"
dev-libs/libmemcached
dev-php/PEAR-Mail
dev-php/PEAR-Mail_Mime
dev-php/PEAR-Spreadsheet_Excel_Writer
dev-php/smarty
dev-qt/qtwebkit
net-libs/libssh2
media-video/ffmpeg
sys-apps/miscfiles
sys-fs/s3fs
www-apache/mod_fcgid
www-servers/apache
EOF

filename="/etc/portage/package.use/apache"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
www-servers/apache apache2_modules_log_forensic
EOF

filename="/etc/portage/package.use/libmemcachd"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
dev-libs/libmemcached sasl
EOF

filename="/etc/portage/package.use/php"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
dev-lang/php apache2 bcmath calendar cgi curl exif ftp gd inifile intl pcntl pdo sharedmem snmp soap sockets spell sysvipc truetype xmlreader xmlrpc xmlwriter zip
app-eselect/eselect-php apache2
EOF

dirname="/etc/portage/package.keywords"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

filename="/etc/portage/package.keywords/libmemcachd"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
dev-libs/libmemcached
EOF

emerge -uDN @system @world || exit 1

filename="/etc/php/apache2-php5.6/php.ini"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s|^(short_open_tag\s+=\s+).*|\1On|" \
-e "s|^(expose_php\s+=\s+).*|\1Off|" \
-e "s|^(error_reporting\s+=\s+).*|\1E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED|" \
-e "s|^(display_errors\s+=\s+).*|\1Off|" \
-e "s|^(display_startup_errors\s+=\s+).*|\1Off|" \
-e "s|^(track_errors\s+=\s+).*|\1Off|" \
-e "s|^;(date\.timezone\s+=).*|\1 America/Denver|" \
"${filename}" || exit 1

filename="/etc/php/cgi-php5.6/php.ini"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s|^(short_open_tag\s+=\s+).*|\1On|" \
-e "s|^(expose_php\s+=\s+).*|\1Off|" \
-e "s|^(error_reporting\s+=\s+).*|\1E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED|" \
-e "s|^(display_errors\s+=\s+).*|\1Off|" \
-e "s|^(display_startup_errors\s+=\s+).*|\1Off|" \
-e "s|^(track_errors\s+=\s+).*|\1Off|" \
-e "s|^;(date\.timezone\s+=).*|\1 America/Denver|" \
"${filename}" || exit 1

dirname="/usr/share/php/smarty"
linkname="/usr/share/php/Smarty"
echo "--- ${linkname} -> ${dirname} (softlink)"
ln -s "${dirname}/" "${linkname}"

filename="/etc/conf.d/apache2"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s|^APACHE2_OPTS=\"(.*)\"|APACHE2_OPTS=\"-D INFO -D SSL -D LANGUAGE -D PHP5 -D FCGID\"|" \
"${filename}" || exit 1

filename="/etc/apache2/modules.d/00_default_settings.conf"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s|^(Timeout\s+).*|\130|" \
-e "s|^(KeepAliveTimeout\s+).*|\13|" \
-e "s|^(ServerSignature\s+).*|\1Off|" \
"${filename}" || exit 1

filename="/tmp/00_mod_log_config.conf.insert"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
LogFormat "%P %{Host}i %h %{%Y-%m-%d %H:%M:%S %z}t %m %U %H %>s %B %D" stats
LogFormat "%P %{Host}i %h %{%Y-%m-%d %H:%M:%S %z}t %{User-Agent}i" agents
LogFormat "%>s %h" status

ErrorLog "|php /usr/local/lib64/apache2/error.php"

CustomLog "|php /usr/local/lib64/apache2/stats.php" stats
CustomLog "|php /usr/local/lib64/apache2/agents.php" agents
CustomLog "|php /usr/local/lib64/apache2/status.php" status

ForensicLog /var/log/apache2/forensic_log

EOF

filename="/etc/apache2/modules.d/00_mod_log_config.conf"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "\|log_config_module|r /tmp/00_mod_log_config.conf.insert" \
"${filename}" || exit 1

filename="/etc/apache2/modules.d/00_mpm.conf"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "\|prefork MPM|i ServerLimit 1024\n" \
-e "\|^<IfModule mpm_prefork_module>|,\|^</IfModule>|s|^(\s+MaxClients\s+).*|\11024|" \
"${filename}" || exit 1

filename="/etc/apache2/vhosts.d/01_isdc_lmp_vhost.conf"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
Listen 80
Listen 8443

NameVirtualHost *:80
NameVirtualHost *:8443

ExpiresActive On
ExpiresByType text/css "access plus 2 hours"
ExpiresByType image/gif "access plus 2 hours"
ExpiresByType image/png "access plus 2 hours"
ExpiresByType image/jpeg "access plus 2 hours"
ExpiresByType image/x-icon "access plus 2 hours"
ExpiresByType application/x-javascript "access plus 2 hours"
ExpiresByType application/x-shockwave-flash "access plus 2 hours"

AddOutputFilterByType DEFLATE text/plain
AddOutputFilterByType DEFLATE text/html
AddOutputFilterByType DEFLATE text/xml
AddOutputFilterByType DEFLATE text/css
AddOutputFilterByType DEFLATE application/xml
AddOutputFilterByType DEFLATE application/xhtml+xml
AddOutputFilterByType DEFLATE application/rss+xml
AddOutputFilterByType DEFLATE application/x-javascript

Include /var/www/sta/conf/insidesales.com.conf
Include /var/www/sta2/conf/beta.insidesales.com.conf
EOF

filename="/etc/apache2/vhosts.d/02_isdc_other_vhost.conf"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
Include /var/www/cdn/conf/insidesales.com.conf

Include /var/www/iswsi/conf/insidesales.com.conf
Include /var/www/iswsi2/conf/beta.insidesales.com.conf

Include /var/www/arkapi/conf/insidesales.com.conf
Include /var/www/arkapi2/conf/beta.insidesales.com.conf

Include /var/www/nvapi/conf/insidesales.com.conf
Include /var/www/nvapi2/conf/beta.insidesales.com.conf

Include /var/www/idm/conf/insidesales.com.conf
Include /var/www/idm2/conf/beta.insidesales.com.conf

Include /var/www/accounting/conf/insidesales.com.conf
Include /var/www/accounting2/conf/beta.insidesales.com.conf

Include /var/www/dialerapp2/conf/beta.insidesales.com.conf
Include /var/www/dialerapp/conf/insidesales.com.conf

Include /var/www/is/atom/conf/insidesales.com.conf
Include /var/www/is/atom2/conf/beta.insidesales.com.conf

Include /var/www/is/billing/conf/insidesales.com.conf
Include /var/www/is/billing2/conf/beta.insidesales.com.conf
EOF

for d in $(grep -h ^Include /etc/apache2/vhosts.d/01_isdc_lmp_vhost.conf /etc/apache2/vhosts.d/02_isdc_other_vhost.conf | cut -d' ' -f2); do
	dirname="${d%/*}"
	echo "--- ${dirname} (create)"
	mkdir -p "${dirname}"

	filename="${d}"
	echo "--- ${filename} (create)"
	touch "${filename}"
done

dirname="/usr/local/lib64/apache2/include"
echo "--- ${dirname} (create)"
mkdir -p "${dirname}"

filename="/usr/local/lib64/apache2/agents.php"
echo "--- ${filename} (replace)"
curl -sf -o "${filename}" "${scripts}${filename}" || exit 1
chmod 755 "${filename}"

filename="/usr/local/lib64/apache2/error.php"
echo "--- ${filename} (replace)"
curl -sf -o "${filename}" "${scripts}${filename}" || exit 1
chmod 755 "${filename}"

filename="/usr/local/lib64/apache2/stats.php"
echo "--- ${filename} (replace)"
curl -sf -o "${filename}" "${scripts}${filename}" || exit 1
chmod 755 "${filename}"

filename="/usr/local/lib64/apache2/status.php"
echo "--- ${filename} (replace)"
curl -sf -o "${filename}" "${scripts}${filename}" || exit 1
chmod 755 "${filename}"

filename="/usr/local/lib64/apache2/include/settings.inc"
echo "--- ${filename} (replace)"
curl -sf -o "${filename}" "${scripts}${filename}" || exit 1

user="stats"
app="mysql"
type="auth"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

filename="/usr/local/lib64/apache2/include/settings.inc"
echo "--- ${filename} (modify)"
sed -i -r \
-e "s|%STATS_AUTH%|${stats_mysql_auth}|" \
"${filename}" || exit 1

/etc/init.d/apache2 start || exit 1

rc-update add apache2 default

for i in memcache memcached mongo oauth ssh2-beta; do
	yes "" | pecl install "${i}" || exit 1

	dirname="/etc/php"
	echo "--- ${dirname} (processing)"

	for j in $(ls "${dirname}"); do
		filename="${dirname}/${j}/ext/${i%-*}.ini"
		echo "--- ${filename} (replace)"
		cat <<EOF>"${filename}"
extension=${i%-*}.so
EOF

		filename="${dirname}/${j}/ext/${i%-*}.ini"
		linkname="${dirname}/${j}/ext-active/${i%-*}.ini"
		echo "--- ${linkname} -> ${filename} (softlink)"
		ln -s "${filename}" "${linkname}"
	done
done

filename="/usr/local/bin/wkhtmltopdf"
echo "--- ${filename} (replace)"
curl -sf --compressed -o "${filename}" "http://download.gna.org/wkhtmltopdf/obsolete/linux/wkhtmltopdf-0.11.0_rc1-static-amd64.tar.bz2" || exit 1
chmod 755 "${filename}"
ln -s "${filename}" /usr/bin

filename="/usr/local/bin/wkhtmltoimage"
echo "--- ${filename} (replace)"
curl -sf --compressed -o "${filename}" "http://download.gna.org/wkhtmltopdf/obsolete/linux/wkhtmltoimage-0.11.0_rc1-static-amd64.tar.bz2" || exit 1
chmod 755 "${filename}"
ln -s "${filename}" /usr/bin
