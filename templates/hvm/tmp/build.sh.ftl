#!/bin/bash

echo "Setup files"

<#assign filename = "/etc/fstab">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/fstab.ftl">
EOF

<#assign filename = "/etc/local.d/makeopts.start">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/local.d/makeopts.start.ftl">
EOF
chmod 755 ${filename}

<#assign filename = "/etc/timezone">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/timezone.ftl">
EOF

<#assign filename = "/etc/portage/make.conf">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/portage/make.conf.ftl">
EOF

<#assign filename = "/etc/sudoers.d/_wheel">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/sudoers.d/_wheel.ftl">
EOF
chmod 440 ${filename}

<#assign filename = "/var/lib/portage/world">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/var/lib/portage/world.ftl">
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
emerge --update --deep --with-bdeps=y --newuse @world

cd /usr/src/linux
<#assign filename = "/usr/src/linux/.config">
echo "${filename}"
cat <<'__EOF__'>${filename}
<#include "/usr/src/linux/.config.ftl">
__EOF__

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
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/keys/bmoorman.ftl">
EOF

useradd -g users -G wheel -m npeterson

<#assign filename = "/home/npeterson/.ssh/authorized_keys">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/keys/npeterson.ftl">
EOF

useradd -g users -G wheel -m sdibb

<#assign filename = "/home/sdibb/.ssh/authorized_keys">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/keys/sdibb.ftl">
EOF

ln -s /etc/init.d/net.lo /etc/init.d/net.eth0

rc-update add net.eth0 default
rc-update add sshd default
rc-update add syslog-ng default
rc-update add vixie-cron default
rc-update add ntpd default
rc-update add svscan default

emerge sys-boot/grub-static

<#assign filename = "/boot/grub/menu.lst">
echo "${filename}"
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
