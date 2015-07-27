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

filename="/var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"
net-analyzer/nagios
sys-cluster/ganglia-web
sys-fs/s3fs
www-servers/apache
EOF

filename="/etc/portage/package.use/nagios"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
net-analyzer/nagios-core apache2
EOF

filename="/etc/portage/package.use/php"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
dev-lang/php apache2 cgi gd
app-eselect/eselect-php apache2
EOF

filename="/etc/portage/package.use/gd"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
media-libs/gd jpeg png
EOF

filename="/etc/portage/package.use/ganglia"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
sys-cluster/ganglia python
EOF

emerge -uDN @world

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
"${filename}"

filename="/etc/conf.d/apache2"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s|^APACHE2_OPTS=\"(.*)\"|APACHE2_OPTS=\"\1 -D PHP5 -D NAGIOS\"|" \
"${filename}"

/etc/init.d/apache2 start

rc-update add apache2 default

filename="/usr/lib/nagios/cgi-bin/.htaccess"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
AuthType Basic
AuthName "Authorization is required beyond this point!"
AuthUserFile /etc/nagios/auth.users
Require valid-user
EOF

filename="/usr/share/nagios/htdocs/.htaccess"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
AuthType Basic
AuthName "Authorization is required beyond this point!"
AuthUserFile /etc/nagios/auth.users
Require valid-user
EOF

filename="/etc/nagios/cgi.cfg"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s|nagiosadmin|bmoorman,npeterson,sdibb|" \
"${filename}"

filename="/tmp/nagios.cfg.insert"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"

cfg_dir=/etc/nagios/global
cfg_dir=/etc/nagios/aws
EOF

filename="/etc/nagios/nagios.cfg"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "\|^#cfg_dir=/etc/nagios/routers|r /tmp/nagios.cfg.insert" \
-e "s|^(check_result_reaper_frequency=).*|\12|" \
-e "s|^(use_large_installation_tweaks=).*|\11|" \
-e "s|^(enable_environment_macros=).*|\10|" \
"${filename}"

dirname="/etc/nagios/global"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

#
# TODO: Add GLOBAL configs
#

dirname="/etc/nagios/aws"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

#
# TODO: Add AWS configs
#

dirname="/etc/nagios/scripts/include"
echo "--- $dirname (create)"
mkdir -p "${dirname}"

curl --silent -o /etc/nagios/scripts/include/nma.php https://raw.githubusercontent.com/iVirus/NMA-PHP/master/nma.php
curl --silent -o /etc/nagios/scripts/include/prowl.php https://raw.githubusercontent.com/iVirus/Prowl-PHP/master/prowl.php

#
# TODO: Add SCRIPTS
#

/etc/init./nagios start

rc-update add nagios default

filename="/tmp/gmetad.conf.insert"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"

data_source "Database" db1_0 db1_1 db1_2 db2_0 db2_1 db2_2 db3_0 db3_1 db3_2 db4_0 db4_1 db4_2 db5_0 db5_1 db5_2
data_source "Deplopy" deploy1
data_source "Dialer"  sip1 sip2 sip3 sip4 sip5
data_source "Event Handler" eh1 eh2
data_source "Inbound" inbound1 inbound2
data_source "Joule Processor" jp1 jp2
data_source "Log" log1
data_source "Message Queue" mq1 mq2
data_source "MongoDB" mdb1 mdb2 mdb3
data_source "Monitor" monitor1
data_source "Name Server" ns1 ns2
data_source "Public Web" pub1 pub2
data_source "Socket" socket1 socket2
data_source "Statistics" stats1
data_source "Systems" systems1
data_source "Web" web1 web2 web3 web4
data_source "Worker" worker1
EOF

filename="/etc/ganglia/gmetad.conf"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s|^(data_source .*)|#\1|" \
-e "\|^#data_source|r /tmp/gmetad.conf.insert"
-e "s|^# gridname .*|gridname \"ISDC-EU\"|"
"${filename}"

filename="/etc/fstab"
echo "--- ${filename} (append)"
cat <<'EOF'>>"${filename}"

tmpfs		/var/lib/ganglia/rrds	tmpfs		size=16G	0 0
EOF

dirname="/var/lib/ganglia/rrds"
echo "--- ${dirname} (mount)"
mv "${dirname}" "${dirname}-disk"
mkdir -p "${dirname}"
mount "${dirname}"
rsync -a "${dirname}-disk/" "${dirname}/"

filename="/tmp/gmetad.start"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
	ebegin "Syncing disk to tmpfs: "
	if [ -f "/var/lib/ganglia/rrds-disk/.keep_sys-cluster_ganglia-0" ]; then
		rsync -aq --del /var/lib/ganglia/rrds-disk/ /var/lib/ganglia/rrds/
	fi
	eend $?

EOF

filename="/tmp/gmetad.stop"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"

	ebegin "Syncing tmpfs to disk: "
	if [ -f "/var/lib/ganglia/rrds/.keep_sys-cluster_ganglia-0" ]; then
		rsync -aq --del /var/lib/ganglia/rrds/ /var/lib/ganglia/rrds-disk/
	fi
	eend $?
EOF

filename="/etc/init.d/gmetad"
echo "--- ${filename} (modify)"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "\|^start|r /tmp/gmetad.start" \
-e "\|Failed to stop gmetad|r /tmp/gmetad.stop" \
"${filename}"

/etc/init.d/gmetad start

rc-update add gmetad default

dirname="/usr/local/lib64/ganglia"
echo "--- ${dirname} (create)"
mkdir -p "${dirname}"

filename="/usr/local/lib64/ganglia/persist"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
#!/bin/bash

if [ -f "/var/lib/ganglia/rrds/.keep_sys-cluster_ganglia-0" ]; then
	rsync -avzq --del /var/lib/ganglia/rrds/ /var/lib/ganglia/rrds-disk/
fi
EOF
chmod 755 "${filename}"

filename="/var/spool/cron/crontabs/root"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"

45 */3 * * *	bash /usr/local/lib64/ganglia/persist
EOF
touch /var/spool/cron/crontabs

ln -s /var/www/localhost/htdocs/ganglia-web/ /var/www/localhost/htdocs/ganglia

filename="/var/www/localhost/htdocs/ganglia/.htaccess"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
SetEnv ganglia_secret MVedpvR6jqdTnREhHunaqzrX
AuthType Basic
AuthName "Authorization is required beyond this point!"
AuthUserFile /etc/ganglia/auth.users
Require valid-user
EOF

filename="/var/www/localhost/htdocs/ganglia/conf.php"
echo "--- ${filename} (replace)"
cat <<'EOF'>"${filename}"
$acl = GangliaAcl::getInstance();

$acl->addPrivateCluster('Database');
$acl->addPrivateCluster('Deplopy');
$acl->addPrivateCluster('Dialer');
$acl->addPrivateCluster('Event Handler');
$acl->addPrivateCluster('Inbound');
$acl->addPrivateCluster('Joule Processor');
$acl->addPrivateCluster('Log');
$acl->addPrivateCluster('Message Queue');
$acl->addPrivateCluster('MongoDB');
$acl->addPrivateCluster('Monitor');
$acl->addPrivateCluster('Name Server');
$acl->addPrivateCluster('Public Web');
$acl->addPrivateCluster('Socket');
$acl->addPrivateCluster('Statistics');
$acl->addPrivateCluster('Systems');
$acl->addPrivateCluster('Web');
$acl->addPrivateCluster('Worker');

$acl->addRole('bmoorman', GangliaAcl::ADMIN);
$acl->addRole('npeterson', GangliaAcl::ADMIN);
$acl->addRole('sdibb', GangliaAcl::ADMIN);
EOF
