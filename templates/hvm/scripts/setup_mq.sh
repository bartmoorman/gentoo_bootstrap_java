#!/bin/bash
while getopts ":p:b:h:e:" OPTNAME; do
	case $OPTNAME in
		p)
			echo "Peer: ${OPTARG}"
			peer="${OPTARG}"
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

if [ -z "${peer}" -o -z "${bucket_name}" ]; then
	echo "Usage: ${BASH_SOURCE[0]} -p peer_name:peer_ip -b files_bucket_name [-h hostname_prefix] [-e environment_suffix]"
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
net-misc/rabbitmq-server
sys-fs/s3fs
EOF

dirname="etc/portage/package.keywords"
echo "--- ${dirname} (create)"
mkdir -p "/${dirname}"

filename="etc/portage/package.keywords/rabbitmq-server"
echo "--- ${filename} (replace)"
cat <<'EOF'>"/${filename}"
net-misc/rabbitmq-server
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

filename="etc/rabbitmq/rabbitmq.config"
echo "--- ${filename} (replace)"
cat <<EOF>"/${filename}"
[
  {rabbit, [
    {cluster_nodes, {['rabbit@${name}', 'rabbit@${peer%:*}'], disc}},
    {loopback_users, []}
  ]}
].
EOF

user="rabbitmq"
app="erlang"
type="cookie"
echo "-- ${user} ${app}_${type} (decrypt)"
declare "${user}_${app}_${type}=$(decrypt_user_text "${app}_${type}" "${user}")"

filename="var/lib/rabbitmq/.erlang.cookie"
echo "--- ${filename} (replace)"
cat <<EOF>"/${filename}"
${rabbitmq_erlang_cookie}
EOF
chmod 600 "/${filename}" || exit 1
chown rabbitmq: "/${filename}" || exit 1

/etc/init.d/rabbitmq start || exit 1

rc-update add rabbitmq default

rabbitmq-plugins enable rabbitmq_management rabbitmq_stomp || exit 1

nrpe_file="$(mktemp)"
cat <<'EOF'>"${nrpe_file}"

command[check_s3fs]=/usr/lib64/nagios/plugins/check_procs -c 1: -C s3fs -a s3fs
command[check_rabbitmq]=/usr/lib64/nagios/plugins/check_procs -c 1: -C beam -a /var/lib/rabbitmq
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
-e "\|^cluster\s+\{$|,\|^\}$|s|(\s+name\s+\=\s+)\".*\"|\1\"Message Queue\"|" \
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
