#!/bin/bash
while getopts "b:" OPTNAME; do
	case $OPTNAME in
		b)
			echo "Bucket Name: ${OPTARG}"
			bucket_name="${OPTARG}"
			;;
	esac
done

if [ -z "${bucket_name}" ]; then
	echo "Usage: ${BASH_SOURCE[0]} -b bucket_name"
	exit 1
fi

iam_role="$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="usr/local/bin/encrypt_decrypt"
functions_file="$(mktemp)"
curl -sf -o "${functions_file}" "${scripts}/${filename}" || exit 1
source "${functions_file}"

filename="var/lib/portage/world"
echo "--- ${filename} (append)"
cat <<'EOF'>>"/${filename}"
net-analyzer/nagios
sys-cluster/ganglia-web
sys-fs/s3fs
www-servers/apache
EOF

filename="etc/portage/package.use/apache"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
www-servers/apache apache2_modules_log_forensic
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

emerge -uDN @system @world || exit 1

filename="etc/fstab"
echo "--- ${filename} (append)"
cat <<EOF>>"/${filename}"

s3fs#${bucket_name}	/mnt/s3		fuse	_netdev,allow_other,url=https://s3.amazonaws.com,iam_role=${iam_role}	0 0
EOF

dirname="mnt/s3"
echo "--- ${dirname} (mount)"
mkdir -p "/${dirname}"
mount "/${dirname}" || exit 1

filename="etc/php/apache2-php5.6/php.ini"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^(short_open_tag\s+=\s+).*|\1On|" \
-e "s|^(expose_php\s+=\s+).*|\1Off|" \
-e "s|^(error_reporting\s+=\s+).*|\1E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED|" \
-e "s|^(display_errors\s+=\s+).*|\1Off|" \
-e "s|^(display_startup_errors\s+=\s+).*|\1Off|" \
-e "s|^(track_errors\s+=\s+).*|\1Off|" \
-e "s|^;(date\.timezone\s+=).*|\1 America/Denver|" \
"/${filename}" || exit 1

filename="etc/conf.d/apache2"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^APACHE2_OPTS=\"(.*)\"|APACHE2_OPTS=\"\1 -D PHP5 -D NAGIOS\"|" \
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

user="sdibb"
app="nagios"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="tlosee"
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
sdibb:${sdibb_nagios_hash}
tlosee:${tlosee_nagios_hash}
tpurdy:${tpurdy_nagios_hash}
EOF

filename="etc/nagios/cgi.cfg"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|nagiosadmin|bmoorman,npeterson,sdibb,tlosee,tpurdy|" \
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
-e "s|^(cfg_file=.*)|#\1|" \
-e "\|^#cfg_dir=/etc/nagios/routers|r ${nagios_file}" \
-e "s|^(check_result_reaper_frequency=).*|\12|" \
-e "s|^(use_large_installation_tweaks=).*|\11|" \
-e "s|^(enable_environment_macros=).*|\10|" \
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

user="sdibb"
app="nagios"
type="nma"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="tlosee"
app="nagios"
type="prowl"
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
-e "s|%SDIBB_NMA%|${sdibb_nagios_nma}|" \
-e "s|%TLOSEE_PROWL%|${tlosee_nagios_prowl}|" \
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
cat <<'EOF'>"${ganglia_file}"
data_source "Backup" eu1iec1backup1
data_source "Database" eu1iec1db1_0 eu1iec1db1_1 eu1iec1db1_2 eu1iec1db2_0 eu1iec1db2_1 eu1iec1db2_2 eu1iec1db3_0 eu1iec1db3_1 eu1iec1db3_2 eu1iec1db4_0 eu1iec1db4_1 eu1iec1db4_2 eu1iec1db5_0 eu1iec1db5_1 eu1iec1db5_2
data_source "Deplopy" eu1iec1deploy1
data_source "Dialer"  eu1iec1sip1 eu1iec1sip2 eu1iec1sip3 eu1iec1sip4 eu1iec1sip5
data_source "Event Handler" eu1iec1eh1 eu1iec1eh2
data_source "Inbound" eu1iec1inbound1 eu1iec1inbound2
data_source "Joule Processor" eu1iec1jp1 eu1iec1jp2
data_source "Log" eu1iec1log1
data_source "Message Queue" eu1iec1mq1 eu1iec1mq2
data_source "MongoDB" eu1iec1mdb1 eu1iec1mdb2 eu1iec1mdb3
data_source "Monitor" eu1iec1monitor1
data_source "Name Server" eu1iec1ns1 eu1iec1ns2
data_source "Public Web" eu1iec1pub1 eu1iec1pub2
data_source "Socket" eu1iec1socket1 eu1iec1socket2
data_source "Statistics" eu1iec1stats1
data_source "Systems" eu1iec1systems1
data_source "Web" eu1iec1web1 eu1iec1web2 eu1iec1web3 eu1iec1web4
data_source "Worker" eu1iec1worker1
EOF

filename="etc/ganglia/gmetad.conf"
echo "--- ${filename} (modify)"
cp "/${filename}" "/${filename}.orig"
sed -i -r \
-e "s|^(data_source .*)|#\1|" \
-e "\|^#data_source|r ${ganglia_file}" \
-e "s|^(# gridname .*)|\1\ngridname \"ISDC-EU\"|" \
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
rsync -a "/${dirname}-disk/" "/${dirname}/" || exit 1

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
declare "${user}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

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

user="sdibb"
app="ganglia"
type="hash"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

user="tlosee"
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
sdibb:${sdibb_ganglia_hash}
tlosee:${tlosee_ganglia_hash}
tpurdy:${tpurdy_ganglia_hash}
EOF

filename="var/www/localhost/htdocs/ganglia/conf.php"
echo "--- ${filename} (replace)"
curl -sf -o "/${filename}" "${scripts}/${filename}" || exit 1
