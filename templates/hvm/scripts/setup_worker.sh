#!/bin/bash
while getopts "i:o:b:" OPTNAME; do
	case $OPTNAME in
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
dev-db/mysql
dev-db/mytop
dev-libs/libmemcached
dev-php/PEAR-Mail
dev-php/PEAR-Mail_Mime
dev-php/PEAR-Spreadsheet_Excel_Writer
dev-php/smarty
dev-python/mysql-python
dev-qt/qtwebkit
net-libs/libssh2
net-misc/memcached
sys-apps/miscfiles
sys-apps/pv
sys-process/at
sys-fs/s3fs
EOF

filename="/etc/portage/package.use/libmemcachd"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
dev-libs/libmemcached sasl
EOF

filename="/etc/portage/package.use/mysql"
echo "--- ${filename} (modify)"
sed -i -r \
-e "s|minimal|extraengine profiling|" \
"${filename}" || exit 1

filename="/etc/portage/package.use/php"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
dev-lang/php bcmath calendar curl exif ftp gd inifile intl pcntl pdo sharedmem snmp soap sockets spell sysvipc truetype xmlreader xmlrpc xmlwriter zip
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

filename="/tmp/my.cnf.insert.1"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"

max_connections			= 650
max_user_connections		= 600
skip-name-resolve
sql-mode			= NO_AUTO_CREATE_USER
EOF

filename="/tmp/my.cnf.insert.2"
echo "--- ${filename} (replace)"
cat <<EOF>"${filename}"

expire_logs_days		= 2
slow_query_log
relay-log			= /var/log/mysql/binary/mysqld-relay-bin
log_slave_updates
auto_increment_increment	= 2
auto_increment_offset		= ${offset}
EOF

filename="/etc/mysql/my.cnf"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "\|^lc_messages\s+=\s+|r /tmp/my.cnf.insert.1" \
-e "s|^(bind-address\s+=\s+.*)|#\1|" \
-e "s|^(log-bin)|\1\t\t\t\t= /var/log/mysql/binary/mysqld-bin|" \
-e "s|^(server-id\s+=\s+).*|\1${server_id}|" \
-e "\|^server-id\s+=\s+|r /tmp/my.cnf.insert.2" \
-e "s|^(innodb_data_file_path\s+=\s+.*)|#\1|" \
"${filename}" || exit 1

dirname="/var/log/mysql/binary"
echo "--- ${dirname} (create)"
mkdir -p "${dirname}"
chmod 700 "${dirname}"
chown mysql: "${dirname}"

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

filename="/tmp/configure_as_standalone.sql"
echo "--- ${filename} (replace)"
curl -sf -o "${filename}" "${scripts}${filename}" || exit 1

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

filename="/tmp/configure_as_standalone.sql"
echo "--- ${filename} (modify)"
sed -i -r \
-e "s|%BMOORMAN_HASH%|${bmoorman_mysql_hash}|" \
-e "s|%CPLUMMER_HASH%|${cplummer_mysql_hash}|" \
-e "s|%ECALL_HASH%|${ecall_mysql_hash}|" \
-e "s|%JSTUBBS_HASH%|${jstubbs_mysql_hash}|" \
-e "s|%TPURDY_HASH%|${tpurdy_mysql_hash}|" \
-e "s|%NPETERSON_HASH%|${npeterson_mysql_hash}|" \
-e "s|%MONITORING_AUTH%|${monitoring_mysql_auth}|" \
-e "s|%MYTOP_AUTH%|${mytop_mysql_auth}|" \
"${filename}" || exit 1

filename="/tmp/configure_as_standalone.sql"
echo "--- ${filename} (run)"
mysql < "${filename}" || exit 1

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
