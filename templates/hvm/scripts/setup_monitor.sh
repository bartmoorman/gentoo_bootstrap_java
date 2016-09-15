#!/bin/bash
while getopts ":b:h:e:" OPTNAME; do
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

declare "$(dhcpcd -4T eth0 | grep ^new_domain_name_servers | tr -d \')"

svc -d /service/dnscache || exit 1

filename="var/dnscache/root/servers/@"
echo "--- ${filename} (replace)"
tr ' ' '\n' <<< "${new_domain_name_servers}" > "/${filename}"

svc -u /service/dnscache || exit 1

filename="usr/local/bin/encrypt_decrypt"
functions_file="$(mktemp)"
curl -sf -o "${functions_file}" "${scripts}/${filename}" || exit 1
source "${functions_file}"

filename="etc/ntp.conf"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
restrict 10.0.0.0 mask 255.0.0.0 nomodify nopeer notrap
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
net-analyzer/nagios
net-fs/s3fs
net-misc/memcached
sys-cluster/ganglia-web
www-servers/apache
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
sys-cluster/ganglia python
EOF

filename="etc/portage/package.use/nagios"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
net-analyzer/nagios-core apache2
EOF

filename="etc/portage/package.use/php"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
dev-lang/php apache2 cgi gd
app-eselect/eselect-php apache2
EOF

#mirrorselect -D -b10 -s5 || exit 1

filename="etc/portage/make.conf"
echo "--- ${filename} (modify)"
sed -i -r \
-e "\|^EMERGE_DEFAULT_OPTS|a PORTAGE_BINHOST\=\"http\://${hostname_prefix}bin1/packages\"" \
"/${filename}" || exit 1

#emerge -uDNg @system @world || emerge --resume || exit 1
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

filename="etc/conf.d/memcached"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^MEMUSAGE\=.*|MEMUSAGE\=\"128\"|" \
-e "s|^LISTENON\=.*|LISTENON\=\"127\.0\.0\.1\"|" \
"/${filename}"

/etc/init.d/memcached start || exit 1

rc-update add memcached default

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

filename="etc/conf.d/apache2"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^APACHE2_OPTS\=\"(.*)\"$|APACHE2_OPTS\=\"\1 \-D PHP \-D NAGIOS\"|" \
"/${filename}" || exit 1

/etc/init.d/apache2 start || exit 1

rc-update add apache2 default

filename="usr/lib64/nagios/cgi-bin/.htaccess"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="usr/share/nagios/htdocs/.htaccess"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

user="bmoorman"
app="nagios"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="npeterson"
app="nagios"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="tpurdy"
app="nagios"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

filename="etc/nagios/auth.users"
echo "--- ${filename} (create)"
cat <<EOF>"/${filename}"
bmoorman:${bmoorman_nagios_hash}
npeterson:${npeterson_nagios_hash}
tpurdy:${tpurdy_nagios_hash}
EOF

filename="etc/nagios/cgi.cfg"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|nagiosadmin|bmoorman,npeterson,tpurdy|" \
"/${filename}" || exit 1

nagios_file="$(mktemp)"
cat <<'EOF'>"${nagios_file}"

cfg_dir=/etc/nagios/global
cfg_dir=/etc/nagios/aws
EOF

filename="etc/nagios/nagios.cfg"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^(cfg_file\=.*)|#\1|" \
-e "\|^#cfg_dir\=/etc/nagios/routers|r ${nagios_file}" \
-e "s|^(check_result_reaper_frequency\=).*|\12|" \
-e "s|^(use_large_installation_tweaks\=).*|\11|" \
-e "s|^(enable_environment_macros\=).*|\10|" \
"/${filename}" || exit 1

dirname="etc/nagios/global"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/nagios/global/commands.cfg"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/global/contact_groups.cfg"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/global/contacts.cfg"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

user="bmoorman"
app="nagios"
type="prowl"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="npeterson"
app="nagios"
type="nma"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="tpurdy"
app="nagios"
type="nma"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

sed -i -r \
-e "s|%BMOORMAN_PROWL%|${bmoorman_nagios_prowl}|" \
-e "s|%NPETERSON_NMA%|${npeterson_nagios_nma}|" \
-e "s|%TPURDY_NMA%|${tpurdy_nagios_nma}|" \
"/${filename}" || exit 1

filename="etc/nagios/global/hosts.cfg"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/global/services.cfg"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/global/time_periods.cfg"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

dirname="etc/nagios/aws"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/nagios/aws/host_groups.cfg"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/aws/hosts.cfg"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

sed -i -r \
-e "s|%HOSTNAME_PREFIX%|${hostname_prefix}|" \
"/${filename}" || exit 1

filename="etc/nagios/aws/service_groups.cfg"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/aws/services.cfg"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

dirname="etc/nagios/scripts/include"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/nagios/scripts/build_host_email_message.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/scripts/build_host_push_message.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/scripts/build_service_email_message.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/scripts/build_service_push_message.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/scripts/nma.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/scripts/prowl.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

filename="etc/nagios/scripts/include/nma.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "https://raw.githubusercontent.com/iVirus/NMA-PHP/master/nma.php" || exit 1

filename="etc/nagios/scripts/include/prowl.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "https://raw.githubusercontent.com/iVirus/Prowl-PHP/master/prowl.php" || exit 1

/etc/init.d/nagios start || exit 1

rc-update add nagios default

ganglia_file="$(mktemp)"
cat <<EOF>"${ganglia_file}"
data_source "Database" ${hostname_prefix}db1_0 ${hostname_prefix}db1_1 ${hostname_prefix}db1_2 ${hostname_prefix}db2_0 ${hostname_prefix}db2_1 ${hostname_prefix}db2_2 ${hostname_prefix}db3_0 ${hostname_prefix}db3_1 ${hostname_prefix}db3_2 ${hostname_prefix}db4_0 ${hostname_prefix}db4_1 ${hostname_prefix}db4_2 ${hostname_prefix}db5_0 ${hostname_prefix}db5_1 ${hostname_prefix}db5_2
data_source "Deplopy" ${hostname_prefix}deploy1
data_source "Dialer" ${hostname_prefix}sip1 ${hostname_prefix}sip2 ${hostname_prefix}sip3 ${hostname_prefix}sip4 ${hostname_prefix}sip5
data_source "Event Handler" ${hostname_prefix}eh1 ${hostname_prefix}eh2
data_source "Inbound" ${hostname_prefix}inbound1 ${hostname_prefix}inbound2
data_source "Joule Processor" ${hostname_prefix}jp1 ${hostname_prefix}jp2
data_source "Message Queue" ${hostname_prefix}mq1 ${hostname_prefix}mq2
data_source "MongoDB" ${hostname_prefix}mdb1_0 ${hostname_prefix}mdb1_1 ${hostname_prefix}mdb1_2
data_source "Monitor" ${hostname_prefix}monitor1
data_source "Name Server" ${hostname_prefix}ns1 ${hostname_prefix}ns2
data_source "Public Web" ${hostname_prefix}pub1 ${hostname_prefix}pub2
data_source "Socket" ${hostname_prefix}socket1 ${hostname_prefix}socket2
data_source "Statistics" ${hostname_prefix}stats1
data_source "Systems" ${hostname_prefix}systems1
data_source "Web" ${hostname_prefix}web1 ${hostname_prefix}web2 ${hostname_prefix}web3 ${hostname_prefix}web4
data_source "Worker" ${hostname_prefix}worker1
EOF

filename="etc/ganglia/gmetad.conf"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^(data_source\s+.*)|#\1|" \
-e "\|^#data_source|r ${ganglia_file}" \
-e "s|^(#\s+gridname\s+.*)|\1\ngridname \"${hostname_prefix}\"|" \
"/${filename}" || exit 1

filename="etc/fstab"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"

tmpfs		/var/lib/ganglia/rrds	tmpfs		size=16G	0 0
EOF

dirname="var/lib/ganglia/rrds"
echo "--- ${dirname} (mount)"
mv "/${dirname}" "/${dirname}-disk" || exit 1
mkdir -p "/${dirname}"
mount "/${dirname}" || exit 1
rsync -au "/${dirname}-disk/" "/${dirname}/" || exit 1

gmetad_start_file="$(mktemp)"
cat <<'EOF'>"${gmetad_start_file}"
	ebegin "Syncing disk to tmpfs: "
	if [ -f "/var/lib/ganglia/rrds-disk/.keep_sys-cluster_ganglia-0" ]; then
		rsync -aq --del /var/lib/ganglia/rrds-disk/ /var/lib/ganglia/rrds/
	fi
	eend $?

EOF

gmetad_stop_file="$(mktemp)"
cat <<'EOF'>"${gmetad_stop_file}"

	ebegin "Syncing tmpfs to disk: "
	if [ -f "/var/lib/ganglia/rrds/.keep_sys-cluster_ganglia-0" ]; then
		rsync -aq --del /var/lib/ganglia/rrds/ /var/lib/ganglia/rrds-disk/
	fi
	eend $?
EOF

filename="etc/init.d/gmetad"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "\|^start|r ${gmetad_start_file}" \
-e "\|Failed to stop gmetad|r ${gmetad_stop_file}" \
"/${filename}" || exit 1

/etc/init.d/gmetad start || exit 1

rc-update add gmetad default

dirname="usr/local/lib64/ganglia"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="usr/local/lib64/ganglia/persist.sh"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
chmod 755 "/${filename}" || exit 1

filename="var/spool/cron/crontabs/root"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"

45 */3 * * *	bash /usr/local/lib64/ganglia/persist.sh
EOF
touch "/${filename%/*}" || exit 1

dirname="var/www/localhost/htdocs/ganglia-web"
linkname="var/www/localhost/htdocs/ganglia"
echo "--- ${linkname} -> ${dirname} (softlink)"
ln -s "/${dirname}/" "/${linkname}" || exit 1

filename="var/www/localhost/htdocs/ganglia/.htaccess"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

user="ganglia"
type="secret"
echo "-- ${user} ${type} (decrypt)"
declare "${user}_${type}=$(decrypt_user_text "${type}" "${user}")"

sed -i -r \
-e "s|%GANGLIA_SECRET%|${ganglia_secret}|" \
"/${filename}" || exit 1

user="bmoorman"
app="ganglia"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="npeterson"
app="ganglia"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="tpurdy"
app="ganglia"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

filename="etc/ganglia/auth.users"
echo "--- ${filename} (create)"
cat <<EOF>"/${filename}"
bmoorman:${bmoorman_ganglia_hash}
npeterson:${npeterson_ganglia_hash}
tpurdy:${tpurdy_ganglia_hash}
EOF

filename="var/www/localhost/htdocs/ganglia/conf.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1

nrpe_file="$(mktemp)"
cat <<'EOF'>"${nrpe_file}"

command[check_apache]=/usr/lib64/nagios/plugins/check_procs -c 1:135 -w 5:120 -C apache2 -a /usr/sbin/apache2
command[check_gmetad]=/usr/lib64/nagios/plugins/check_procs -c 1: -C gmetad -a /usr/sbin/gmetad
command[check_memcached]=/usr/lib64/nagios/plugins/check_procs -c 1: -C memcached -a /usr/bin/memcached
command[check_nagios]=/usr/lib64/nagios/plugins/check_procs -c 1: -C nagios -a /usr/sbin/nagios
command[check_s3fs]=/usr/lib64/nagios/plugins/check_procs -c 1: -C s3fs -a s3fs
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
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+name\s+\=\s+)\".*\"|\1\"Monitor\"|" \
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
