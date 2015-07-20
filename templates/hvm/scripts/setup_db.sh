#!/bin/bash
hostname="$(hostname)"

pvcreate /dev/xvd[fg]
vgcreate vg0 /dev/xvd[fg]
lvcreate -l 100%VG -n lvol0 vg0
mkfs.ext4 /dev/vg0/lvol0

filename="/etc/fstab"
echo "--- ${filename} (append)"
echo -e "\n\n/dev/vg0/lvol0\t\t/var/lib/mysql\text4\t\tnoatime\t\t0 0" >> "${filename}"

filename="/var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<EOF>>"${filename}"
dev-db/mysql
dev-db/mytop
dev-python/mysql-python
EOF

filename="/etc/portage/package.use/mysql"
echo "--- ${filename} (modify)"
sed -i -r \
-e "s|minimal|extraengine profiling|" \
"${filename}"

emerge -uDN @world

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

filename="/tmp/my.cnf.insert.1"
echo "--- ${filename} (replace)"
cat <<EOF>>"${filename}"

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
cat <<EOF>>"${filename}"

expire_logs_days		= 2
log_slow_queries
relay-log			= /var/log/mysql/binary/mysqld-relay-bin
log_slave_updates
auto_increment_increment	= 2
auto_increment_offset		= ${offset}
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
"${filename}"

filename="/etc/mysql/sta.key"
echo "--- ${filename} (replace)"
cat <<EOF>>"${filename}"
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

filename="/var/log/mysql/binary"
echo "--- ${filename} (create)"
mkdir -p "${filename}"
chmod 750 "${filename}"
chown mysql: "${filename}"

yes "" | emerge --config dev-db/mysql
/etc/init.d/mysql start

mysql_secure_installation <<EOF

n
y
y
n
y
EOF

mysql <<EOF
USE mysql;

DELETE
FROM user
WHERE User LIKE 'root';

DELETE
FROM db;

GRANT
ALL
ON *.*
TO 'bmoorman'@'%' IDENTIFIED BY PASSWORD '*45BA692206F8B176986CABC043AAEE6143A929B1'
WITH GRANT OPTION;

GRANT
ALL
ON *.*
TO 'cplummer'@'%' IDENTIFIED BY PASSWORD '*64B0067BC8D951A5AD8D57924F8606962ECC4E35'
WITH GRANT OPTION;

GRANT
REPLICATION SLAVE
ON *.*
TO 'replication'@'10.%' IDENTIFIED BY '4Dv2QVfpHsBH48jrcKVwChPn';

GRANT
PROCESS, SUPER, REPLICATION CLIENT
ON *.*
TO 'monitoring'@'localhost' IDENTIFIED BY 'BwaaPPmbdNnsyf3GvZRHfdvA';

GRANT
PROCESS
ON *.*
TO 'mytop'@'localhost' IDENTIFIED BY 'jrquMqj5MtJAHaKrnXKscc8D';

RESET MASTER;

FLUSH PRIVILEGES;

CHANGE MASTER TO
master_host = '${master}',
master_user = 'replication',
master_password = '4Dv2QVfpHsBH48jrcKVwChPn';

START SLAVE;
EOF

/etc/init.d/mysql stop

filename="/var/lib/mysql"
echo "--- ${filename} (mount)"
mv "{$filename}" "{$filename}.bak"
mkdir "{$filename}"
mount "{$filename}"
rsync -a "{$filename}.bak/" "{$filename}/"

/etc/init.d/mysql start
rc-update add mysql default

filename="/etc/skel/.mytop"
echo "--- ${filename} (replace)"
cat <<EOF>"${filename}"
user=mytop
pass=jrquMqj5MtJAHaKrnXKscc8D
delay=1
idle=0
resolve=0
sort=1
EOF
