#!/bin/bash
while getopts "p:i:o:b:h:e:" OPTNAME; do
	case $OPTNAME in
		p)
			echo "Peer: ${OPTARG}"
			peer="${OPTARG}"
			;;
		i)
			echo "Server ID: ${OPTARG}"
			server_id="${OPTARG}"
			;;
		o)
			echo "Offset: ${OPTARG}"
			offset="${OPTARG}"
			;;
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

if [ -z "${peer}" -o -z "${server_id}" -o -z "${offset}" -o -z "${bucket_name}" ]; then
	echo "Usage: ${BASH_SOURCE[0]} -p peer_name:peer_ip -i server_id -o offset -b backup_bucket_name [-h hostname_prefix] [-e environment_suffix]"
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

filename="etc/hosts"
echo "--- ${filename} (append)"
cat <<EOF>>"/${filename}"

${peer#*:}	${peer%:*}.salesteamautomation.com ${peer%:*}
EOF

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
dev-db/mysql
dev-db/mytop
dev-libs/libmemcached
dev-php/PEAR-Mail
dev-php/PEAR-Mail_Mime
dev-php/PEAR-Spreadsheet_Excel_Writer
dev-php/pear
dev-php/smarty
dev-python/mysql-python
dev-qt/qtwebkit
net-libs/libssh2
sys-apps/miscfiles
sys-apps/pv
sys-cluster/glusterfs
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

filename="etc/portage/package.use/mysql"
echo "--- ${filename} (modify)"
sed -i -r \
-e "s|minimal|extraengine profiling|" \
"/${filename}" || exit 1

filename="etc/portage/package.use/php"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-lang/php apache2 bcmath calendar cgi curl exif ftp gd inifile intl pcntl pdo sharedmem snmp soap sockets spell sysvipc truetype xmlreader xmlrpc xmlwriter zip
app-eselect/eselect-php apache2
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

mirrorselect -s5 || exit 1

filename="etc/portage/make.conf"
echo "--- ${filename} (modify)"
sed -i -r \
-e "\|^EMERGE_DEFAULT_OPTS|a PORTAGE_BINHOST\=\"http\://${hostname_prefix}bin1/packages\"" \
"/${filename}" || exit 1

emerge -uDNg @system @world || emerge --resume || exit 1

filename="etc/fstab"
echo "--- ${filename} (append)"
cat <<EOF>>"/${filename}"

s3fs#${bucket_name}	/mnt/s3		fuse	_netdev,allow_other,url=https://s3.amazonaws.com,iam_role=${iam_role}	0 0
EOF

dirname="mnt/s3"
echo "--- ${dirname} (mount)"
mkdir -p "/${dirname}"
mount "/${dirname}" || exit 1

counter=0
timeout=1800
volume="www"

part=30
position=0

if [ "${ip}" \> "${peer#*:}" ]; then
	position=$(bc <<< "${position} + 1")
fi

low=$(bc <<< "(${part} * ${position}) + 5")
high=$(bc <<< "((${part} * ${position}) + ${part}) - 5")
range=($(seq -s' ' ${low} ${high}))
index=$(bc <<< "${RANDOM} % ${#range[@]}")
sleep=${range[${index}]}

dirname="var/glusterfs/${volume}"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

/etc/init.d/glusterd start || exit 1

rc-update add glusterd default

echo -n "Sleeping (${sleep}s)..."
sleep ${sleep}
echo "done! :)"

echo -n "Waiting for ${peer%:*}..."

while true; do
	gluster peer probe ${peer%:*} &> /dev/null && break

	if [ "${counter}" -ge "${timeout}" ]; then
		echo "failed! :("
		exit 1
	fi

	echo -n "."
	sleep ${sleep}
	counter=$(bc <<< "${counter} + ${sleep}")
done

echo "connected! :)"

echo -n "Sleeping (${sleep}s)..."
sleep ${sleep}
echo "done! :)"

if ! gluster volume info ${volume} &> /dev/null; then
	echo "--- ${volume} (manage)"
	gluster volume create ${volume} replica 2 ${name}:/var/glusterfs/${volume} ${peer%:*}:/var/glusterfs/${volume} force || exit 1
	gluster volume set ${volume} auth.allow 127.*,10.*
	gluster volume start ${volume} || exit 1
fi

filename="etc/fstab"
echo "--- ${filename} (append)"
cat <<EOF>>"/${filename}"

localhost:/${volume}	/var/www		glusterfs	_netdev		0 0
EOF

dirname="var/www"
echo "--- ${dirname} (mount)"
mv "/${dirname}" "/${dirname}.bak" || exit 1
mkdir -p "/${dirname}"
mount "/${dirname}" || exit 1
rsync -au "/${dirname}.bak/" "/${dirname}/" || exit 1

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

filename="etc/apache2/vhosts.d/01_isdc_pub_vhost.conf"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

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

my_first_file="$(mktemp)"
cat <<'EOF'>"${my_first_file}"

thread_cache_size		= 64
query_cache_size		= 128M
query_cache_limit		= 32M
tmp_table_size			= 128M
max_heap_table_size		= 128M
max_connections			= 650
max_user_connections		= 600
skip-name-resolve
open_files_limit		= 65536
myisam_repair_threads		= 2
table_definition_cache		= 4096
sql-mode			= NO_AUTO_CREATE_USER
EOF

my_second_file="$(mktemp)"
cat <<EOF>"${my_second_file}"

expire_logs_days		= 2
slow_query_log
relay-log			= /var/log/mysql/binary/mysqld-relay-bin
log_slave_updates
auto_increment_increment	= 2
auto_increment_offset		= ${offset}
EOF

my_third_file="$(mktemp)"
cat <<EOF>"${my_third_file}"

innodb_flush_method		= O_DIRECT
innodb_thread_concurrency	= 48
innodb_concurrency_tickets	= 5000
innodb_io_capacity		= 1000
EOF

filename="etc/mysql/my.cnf"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^(key_buffer_size\s+\=\s+).*|\112288M|" \
-e "s|^(max_allowed_packet\s+\=\s+).*|\116M|" \
-e "s|^(table_open_cache\s+\=\s+).*|\116384|" \
-e "s|^(sort_buffer_size\s+\=\s+).*|\12M|" \
-e "s|^(read_buffer_size\s+\=\s+).*|\1128K|" \
-e "s|^(read_rnd_buffer_size\s+\=\s+).*|\1128K|" \
-e "s|^(myisam_sort_buffer_size\s+\=\s+).*|\164M|" \
-e "\|^lc_messages\s+\=\s+|r ${my_first_file}" \
-e "s|^(bind\-address\s+\=\s+.*)|#\1|" \
-e "s|^(log\-bin)|\1\t\t\t\t\= /var/log/mysql/binary/mysqld\-bin|" \
-e "s|^(server\-id\s+\=\s+).*|\1${server_id}|" \
-e "\|^server\-id\s+\=\s+|r ${my_second_file}" \
-e "s|^(innodb_buffer_pool_size\s+\=\s+).*|\116384M|" \
-e "s|^(innodb_data_file_path\s+\=\s+.*)|#\1|" \
-e "s|^(innodb_log_file_size\s+\=\s+).*|\11024M|" \
-e "s|^(innodb_flush_log_at_trx_commit\s+\=\s+).*|\12|" \
-e "\|^innodb_file_per_table|r ${my_third_file}" \
"/${filename}" || exit 1

dirname="var/log/mysql/binary"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"
chmod 700 "/${dirname}" || exit 1
chown mysql: "/${dirname}" || exit 1

yes "" | emerge --config dev-db/mysql || exit 1

/etc/init.d/mysql start || exit 1

rc-update add mysql default

mysql_secure_installation <<'EOF'

n
y
y
n
y
EOF

filename="etc/mysql/configure_as_slave.sql"
configure_slave_file="$(mktemp)"
curl -sf -o "${configure_slave_file}" "${scripts}/${filename}" || exit 1

user="bmoorman"
app="mysql"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="cplummer"
app="mysql"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="ecall"
app="mysql"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="jstubbs"
app="mysql"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="tpurdy"
app="mysql"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="npeterson"
app="mysql"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="replication"
app="mysql"
type="auth"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="monitoring"
app="mysql"
type="auth"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="mytop"
app="mysql"
type="auth"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="master"
app="mysql"
type="auth"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

sed -i -r \
-e "s|%BMOORMAN_HASH%|${bmoorman_mysql_hash}|" \
-e "s|%CPLUMMER_HASH%|${cplummer_mysql_hash}|" \
-e "s|%ECALL_HASH%|${ecall_mysql_hash}|" \
-e "s|%JSTUBBS_HASH%|${jstubbs_mysql_hash}|" \
-e "s|%TPURDY_HASH%|${tpurdy_mysql_hash}|" \
-e "s|%NPETERSON_HASH%|${npeterson_mysql_hash}|" \
-e "s|%REPLICATION_AUTH%|${replication_mysql_auth}|" \
-e "s|%MONITORING_AUTH%|${monitoring_mysql_auth}|" \
-e "s|%MYTOP_AUTH%|${mytop_mysql_auth}|" \
-e "s|%MASTER_HOST%|${peer%:*}|" \
-e "s|%MASTER_AUTH%|${master_mysql_auth}|" \
"${configure_slave_file}" || exit 1

mysql < "${configure_slave_file}" || exit 1

filename="etc/skel/.mytop"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

user="mytop"
app="mysql"
type="auth"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

sed -i -r \
-e "s|%MYTOP_AUTH%|${mytop_mysql_auth}|" \
"/${filename}" || exit 1

nrpe_file="$(mktemp)"
cat <<'EOF'>"${nrpe_file}"

command[check_mysql_disk]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /var/lib/mysql
command[check_mysql_connections]=/usr/lib64/nagios/plugins/custom/check_mysql_connections
command[check_mysql_slave]=/usr/lib64/nagios/plugins/custom/check_mysql_slave
EOF

filename="etc/nagios/nrpe.cfg"
echo "--- ${filename} (modify)"
sed -i -r \
-e "\|^command\[check_total_procs\]|r ${nrpe_file}" \
"/${filename}" || exit 1

/etc/init.d/nrpe restart || exit 1

dirname="usr/lib64/nagios/plugins/custom/include"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="usr/lib64/nagios/plugins/custom/check_mysql_connections"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
chmod 755 "/${filename}" || exit 1

filename="usr/lib64/nagios/plugins/custom/check_mysql_slave"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
chmod 755 "/${filename}" || exit 1

filename="usr/lib64/nagios/plugins/custom/include/settings.inc"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

user="monitoring"
app="mysql"
type="auth"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

sed -i -r \
-e "s|%MONITORING_AUTH%|${monitoring_mysql_auth}|" \
"/${filename}" || exit 1

dirname="usr/local/lib64/mysql/include"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="usr/local/lib64/mysql/watch_mysql_connections.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
chmod 755 "/${filename}" || exit 1

filename="usr/local/lib64/mysql/watch_mysql_slave.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
chmod 755 "/${filename}" || exit 1

filename="usr/local/lib64/mysql/include/settings.inc"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/init.d/watch-mysql-connections"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename%-*}" || exit 1
chmod 755 "/${filename}" || exit 1

/${filename} start || exit 1

rc-update add ${filename##*/} default

filename="etc/init.d/watch-mysql-slave"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename%-*}" || exit 1
chmod 755 "/${filename}" || exit 1

/${filename} start || exit 1

rc-update add ${filename##*/} default

user="monitoring"
app="mysql"
type="auth"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

sed -i -r \
-e "s|%MONITORING_AUTH%|${monitoring_mysql_auth}|" \
"/${filename}" || exit 1

filename="usr/lib64/ganglia/python_modules/DBUtil.py"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "https://raw.githubusercontent.com/ganglia/monitor-core/master/gmond/python_modules/db/mysql.py" || exit 1

filename="usr/lib64/ganglia/python_modules/mysql.py"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "https://raw.githubusercontent.com/ganglia/monitor-core/master/gmond/python_modules/db/DBUtil.py" || exit 1

filename="etc/ganglia/conf.d/mysql.pyconf"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "https://raw.githubusercontent.com/ganglia/monitor-core/master/gmond/python_modules/conf.d/mysql.pyconf.disabled" || exit 1

user="monitoring"
app="mysql"
type="auth"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

sed -i -r \
-e "s|your_user|monitoring|" \
-e "s|your_password|${monitoring_mysql_auth}|" \
-e "\|^\s+param\s+get_master\s+\{$|,\|^\s+\}$|s|False|True|" \
-e "\|^\s+param\s+get_slave\s+\{$|,\|^\s+\}$|s|False|True|" \
"/${filename}"

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
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+name\s+\=\s+)\".*\"|\1\"Public Web\"|" \
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+owner\s+\=\s+)\".*\"|\1\"InsideSales\.com, Inc\.\"|" \
-e "\|^udp_send_channel\s+\{$|,\|^\}$|s|(\s+)(mcast_join\s+\=\s+.*)|\1#\2\n\1host \= ${name}|" \
-e "\|^udp_recv_channel\s+\{$|,\|^\}$|s|(\s+)(mcast_join\s+\=\s+.*)|\1#\2|" \
-e "\|^udp_recv_channel\s+\{$|,\|^\}$|s|(\s+)(bind\s+\=\s+.*)|\1#\2|" \
"/${filename}"

/etc/init.d/gmond start || exit 1

rc-update add gmond default

curl -sf "http://${hostname_prefix}ns1:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || curl -sf "http://${hostname_prefix}ns2:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || exit 1
