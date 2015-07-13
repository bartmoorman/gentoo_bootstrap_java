#!/bin/bash

echo "--- Setup files (inside chroot)"

<#assign filename = "/etc/fstab">
echo "--- ${filename}"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s/^(\/dev\/(BOOT|SWAP))/#\1/" \
-e "s/^\/dev\/ROOT.*/\/dev\/xvda1\t\t\/\t\text4\t\tnoatime,discard\t0 0/" \
"${filename}"

<#assign filename = "/etc/local.d/makeopts.start">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/etc/local.d/makeopts.start.ftl">
EOF
chmod 755 ${filename}

<#assign filename = "/etc/timezone">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/etc/timezone.ftl">
EOF

emerge --config timezone-data

<#assign filename = "/etc/locale.gen">
echo "--- ${filename}"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s/^#(en_US.*)/\1/" \
"${filename}"

locale-gen

<#assign filename = "/etc/portage/make.conf">
echo "--- ${filename}"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s/^(CXXFLAGS=.*)/\1\n/" \
-e "s/^(CHOST=.*)/\1\n/" \
-e "s/^USE=.*/USE=\"mmx sse sse2 mysql mysqli\"\n\nMAKEOPTS=\"-j3\"\nPORTAGE_NICENESS=\"10\"\nEMERGE_DEFAULT_OPTS=\"--jobs=2 --load-average=3.0\"\n/" \
"${filename}"

<#assign filename = "/var/lib/portage/world">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/var/lib/portage/world.ftl">
EOF

<#assign filename = "/etc/portage/package.use/ganglia">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/etc/portage/package.use/ganglia.ftl">
EOF

<#assign filename = "/etc/portage/package.mask/fail2ban">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/etc/portage/package.mask/fail2ban.ftl">
EOF

<#assign filename = "/etc/bash/bashrc.d/aliases">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/etc/bash/bashrc.d/aliases.ftl">
EOF

env-update
source /etc/profile

/etc/local.d/makeopts.start

emerge --sync

emerge --oneshot sys-apps/portage

<#if architecture == "i386">
emerge --unmerge sys-apps/module-init-tools
</#if>

emerge mail-mta/netqmail

<#assign filename = "/var/qmail/control/servercert.cnf">
echo "--- ${filename}"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s/^C=.*/C=US/" \
-e "s/^ST=.*/ST=Utah/" \
-e "s/^L=.*/L=Provo/" \
-e "s/^O=.*/O=InsideSales.com, Inc./" \
-e "s/^emailAddress=.*/emailAddress=systems@insidesales.com/" \
"${filename}"

<#assign filename = "/usr/src/linux/.config">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/usr/src/linux/.config.ftl">
EOF

emerge --update --deep --with-bdeps=y --newuse @world

<#assign filename = "/etc/logrotate.conf">
echo "--- ${filename}"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s/^(dateext)/#\1/" \
"${filename}"

<#assign filename = "/etc/fail2ban/jail.conf">
echo "--- ${filename}"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s/^(ignoreip\s+=\s+.*)/\1 10.0.0.0\/8/" \
-e "s/^(bantime\s+=\s+).*/\1-1/" \
-e "/^\[ssh-tcpwrapper\]/,/^logpath\s+=\s+.*/s/^(enabled\s+=\s+).*/\1true/" \
-e "/^\[ssh-tcpwrapper\]/,/^logpath\s+=\s+.*/s/^(\s+sendmail-whois)/#\1/" \
-e "/^\[ssh-tcpwrapper\]/,/^logpath\s+=\s+.*/s/^(ignoreregex)/#\1/" \
-e "/^\[ssh-tcpwrapper\]/,/^logpath\s+=\s+.*/s/^(logpath\s+=\s+).*/\1\/var\/log\/messages/" \
"${filename}"

<#assign filename = "/etc/nagios/nrpe.cfg">
echo "--- ${filename}"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s/^(allowed_hosts=.*)/\1,10.0.0.0\/8/" \
-e "s/^(command\[check_load\]=.*)/#\1/" \
-e "s/^(command\[check_total_procs\]=.*)/\1\n\n<#include "/etc/nagios/nrpe.cfg.ftl">/" \
"${filename}"

<#assign filename = "/etc/php/cli-php5.6/php.ini">
echo "--- ${filename}"
cp "${filename}" "${filename}.orig"
sed -i -r \
-e "s/^(short_open_tag\s+=\s+).*/\1On/" \
-e "s/^(expose_php\s+=\s+).*/\1Off/" \
-e "s/^(error_reporting\s+=\s+).*/\1E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" \
-e "s/^(display_errors\s+=\s+).*/\1Off/" \
-e "s/^(display_startup_errors\s+=\s+).*/\1Off/" \
-e "s/^(track_errors\s+=\s+).*/\1Off/" \
-e "s/^;(date\.timezone\s+=).*/\1 America\/Denver/" \
"${filename}"

cd /usr/src/linux

yes "" | make oldconfig
make && make modules_install

<#if architecture == "i386">
    <#assign kernelArch = "x86">
<#else>
    <#assign kernelArch = "x86_64">
</#if>
cp -L arch/${kernelArch}/boot/bzImage /boot/bzImage

useradd -g users -G wheel -m bmoorman

<#assign filename = "/home/bmoorman/.ssh/authorized_keys">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/keys/bmoorman.ftl">
EOF

useradd -g users -G wheel -m npeterson

<#assign filename = "/home/npeterson/.ssh/authorized_keys">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/keys/npeterson.ftl">
EOF

useradd -g users -G wheel -m sdibb

<#assign filename = "/home/sdibb/.ssh/authorized_keys">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/keys/sdibb.ftl">
EOF

<#assign filename = "/etc/sudoers.d/_wheel">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/etc/sudoers.d/_wheel.ftl">
EOF
chmod 440 ${filename}

ln -s /etc/init.d/net.lo /etc/init.d/net.eth0

rc-update add net.eth0 default
rc-update add sshd default
rc-update add syslog-ng default
rc-update add vixie-cron default
rc-update add ntp-client default
rc-update add ntpd default
rc-update add svscan default
rc-update add nrpe default
rc-update add fail2ban default

emerge sys-boot/grub-static

<#assign filename = "/boot/grub/menu.lst">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/boot/grub/menu.lst.ftl">
EOF

<#if virtualizationType == "hvm">
grub << EOF
root (hd1,0)
setup (hd1)
quit
EOF
</#if>

<#assign filename = "/etc/sysctl.conf">
echo "--- ${filename}"
cp "${filename}" "${filename}.orig"
echo -e "\nvm.swappiness = 10" >> "${filename}"

<#assign filename = "/etc/hosts.allow">
echo "--- ${filename}"
cp "${filename}" "${filename}.orig"
echo -e "\nnrpe: 10.0.0.0/8" >> "${filename}"

mkdir -p /usr/local/lib64/ganglia

<#assign filename = "/usr/local/lib64/ganglia/conntrack.sh">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/usr/local/lib64/ganglia/conntrack.sh.ftl">
EOF
chmod 755 ${filename}

<#assign filename = "/usr/local/lib64/ganglia/diskstats.php">
echo "--- ${filename}"
cat <<'EOF'>${filename}
<#include "/usr/local/lib64/ganglia/diskstats.php.ftl">
EOF
chmod 755 ${filename}
