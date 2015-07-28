#!/bin/bash
hostname="$(hostname)"
mac="$(curl -s http://169.254.169.254/latest/meta-data/mac)"
if [ -z "${mac}" ]; then
	echo "Unable to determine MAC!"
	exit 1
fi
ip="$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac}/local-ipv4s)"
if [ -z "${ip}" ]; then
	echo "Unable to determine IP!"
	exit 1
fi

scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

if [ "${hostname##*_}" -eq "0" ]; then
	master="${hostname%_*}_1"
	id="1"
	offset="1"
elif [ "${hostname##*_}" -eq "1" ]; then
	master="${hostname%_*}_0"
	id="2"
	offset="2"
elif [ "${hostname##*_}" -eq "2" ]; then
	master="${hostname%_*}_1"
	id="3"
	offset="1"
fi

filename="/var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"
dev-db/mysql
dev-db/mytop
dev-python/mysql-python
sys-apps/pv
sys-fs/lvm2
sys-fs/s3fs
EOF

filename="/etc/portage/package.use/lvm2"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
sys-fs/lvm2 -thin
EOF

filename="/etc/portage/package.use/mysql"
echo "--- ${filename} (modify)"
sed -i -r \
-e "s|minimal|extraengine profiling|" \
"${filename}"

emerge -uDN @world

filename="/tmp/my.cnf.insert.1"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"

des-key-file			= /etc/mysql/sta.key
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

filename="/tmp/my.cnf.insert.3"
echo "--- ${filename} (replace)"
cat <<EOF>"${filename}"

innodb_flush_method		= O_DIRECT
innodb_thread_concurrency	= 48
innodb_concurrency_tickets	= 5000
innodb_io_capacity		= 1000
EOF

filename="/etc/mysql/my.cnf"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s|^(key_buffer_size\s+=\s+).*|\124576M|" \
-e "s|^(max_allowed_packet\s+=\s+).*|\116M|" \
-e "s|^(table_open_cache\s+=\s+).*|\116384|" \
-e "s|^(sort_buffer_size\s+=\s+).*|\12M|" \
-e "s|^(read_buffer_size\s+=\s+).*|\1128K|" \
-e "s|^(read_rnd_buffer_size\s+=\s+).*|\1128K|" \
-e "s|^(myisam_sort_buffer_size\s+=\s+).*|\164M|" \
-e "\|^lc_messages\s+=\s+|r /tmp/my.cnf.insert.1" \
-e "s|^(bind-address\s+=\s+.*)|#\1|" \
-e "s|^(log-bin)|\1\t\t\t\t= /var/log/mysql/binary/mysqld-bin|" \
-e "s|^(server-id\s+=\s+).*|\1${id}|" \
-e "\|^server-id\s+=\s+|r /tmp/my.cnf.insert.2" \
-e "s|^(innodb_buffer_pool_size\s+=\s+).*|\132768M|" \
-e "s|^(innodb_data_file_path\s+=\s+.*)|#\1|" \
-e "s|^(innodb_log_file_size\s+=\s+).*|\11024M|" \
-e "s|^(innodb_flush_log_at_trx_commit\s+=\s+).*|\12|" \
-e "\|^innodb_file_per_table|r /tmp/my.cnf.insert.3" \
"${filename}"

filename="/etc/mysql/sta.key"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
0 
1 
2 
3 
4 
5 
6 
7 
8 
9 
EOF
chmod 600 "${filename}"
chown mysql: "${filename}"

dirname="/var/log/mysql/binary"
echo "--- ${dirname} (create)"
mkdir -p "${dirname}"
chmod 700 "${dirname}"
chown mysql: "${dirname}"

yes "" | emerge --config dev-db/mysql
/etc/init.d/mysql start

mysql_secure_installation <<'EOF'

n
y
y
n
y
EOF

filename="/etc/mysql/configure_as_slave.sql"
echo "--- ${filename} (replace)"
curl --silent -o "${filename}" "${scripts}${filename}"
mysql < "${filename}"

/etc/init.d/mysql stop

pvcreate /dev/xvd[fg]
vgcreate vg0 /dev/xvd[fg]
lvcreate -l 100%VG -n lvol0 vg0
mkfs.ext4 /dev/vg0/lvol0

filename="/etc/fstab"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"

/dev/vg0/lvol0		/var/lib/mysql	ext4		noatime		0 0
EOF

dirname="/var/lib/mysql"
echo "--- ${dirname} (mount)"
mv "${dirname}" "${dirname}.bak"
mkdir -p "${dirname}"
mount "${dirname}"
rsync -a "${dirname}.bak/" "${dirname}/"

/etc/init.d/mysql start

rc-update add mysql default

filename="/etc/skel/.mytop"
echo "--- ${filename} (replace)"
curl --silent -o "${filename}" "${scripts}${filename}"

filename="/tmp/nrpe.cfg.insert"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"

command[check_mysql_disk]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /var/lib/mysql
command[check_mysql_connections]=/usr/lib64/nagios/plugins/custom/check_mysql_connections
command[check_mysql_slave]=/usr/lib64/nagios/plugins/custom/check_mysql_slave
EOF

filename="/etc/nagios/nrpe.cfg"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "\|^command\[check_total_procs\]|r /tmp/nrpe.cfg.insert" \
"${filename}"

dirname="/usr/lib64/nagios/plugins/custom/include"
echo "--- ${dirname} (create)"
mkdir -p "${dirname}"

filename="/usr/lib64/nagios/plugins/custom/check_mysql_connections"
echo "--- ${filename} (replace)"
curl --silent -o "${filename}" "${scripts}${filename}"
chmod 755 "${filename}"

filename="/usr/lib64/nagios/plugins/custom/check_mysql_slave"
echo "--- ${filename} (replace)"
curl --silent -o "${filename}" "${scripts}${filename}"
chmod 755 "${filename}"

filename="/usr/lib64/nagios/plugins/custom/include/settings.inc"
echo "--- ${filename} (replace)"
curl --silent -o "${filename}" "${scripts}${filename}"

dirname="/usr/local/lib64/mysql/include"
echo "--- ${dirname} (create)"
mkdir -p "${dirname}"

filename="/usr/local/lib64/mysql/watch_mysql_connections.php"
echo "--- ${filename} (replace)"
curl --silent -o "${filename}" "${scripts}${filename}"
chmod 755 "${filename}"

filename="/usr/local/lib64/mysql/watch_mysql_slave.php"
echo "--- ${filename} (replace)"
curl --silent -o "${filename}" "${scripts}${filename}"
chmod 755 "${filename}"

filename="/usr/local/lib64/mysql/include/settings.inc"
echo "--- ${filename} (replace)"
curl --silent -o "${filename}" "${scripts}${filename}"
