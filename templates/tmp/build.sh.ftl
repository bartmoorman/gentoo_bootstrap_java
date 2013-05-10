#!/bin/bash

echo "Setup files"

mkdir -p /boot/grub

<#assign filename = "/boot/grub/menu.lst">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/boot/grub/menu.lst.ftl">
EOF

mkdir -p /etc

<#assign filename = "/etc/fstab">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/fstab.ftl">
EOF

mkdir -p /etc/local.d

<#assign filename = "/etc/local.d/public-keys.start">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/local.d/public-keys.start.ftl">
EOF
chmod 755 ${filename}

<#assign filename = "/etc/local.d/public-keys.stop">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/local.d/public-keys.stop.ftl">
EOF
chmod 755 ${filename}

<#assign filename = "/etc/local.d/killall_nash-hotplug.start">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/local.d/killall_nash-hotplug.start.ftl">
EOF
chmod 755 ${filename}

<#assign filename = "/etc/local.d/makeopts.start">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/local.d/makeopts.start.ftl">
EOF
chmod 755 ${filename}

echo "/etc/localtime"
cp -L /usr/share/zoneinfo/UTC /etc/localtime

mkdir -p /etc/portage

<#assign filename = "/etc/portage/make.conf">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/portage/make.conf.ftl">
EOF

mkdir -p /etc/sudoers.d

<#assign filename = "/etc/sudoers.d/ec2-user">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/sudoers.d/ec2-user.ftl">
EOF
chmod 440 ${filename}

<#assign filename = "/etc/sudoers.d/_sudo">
echo "${filename}"
cat <<'EOF'>${filename}
<#include "/etc/sudoers.d/_sudo.ftl">
EOF
chmod 440 ${filename}

mkdir -p /var/lib/portage

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
    <#assign gentooProfile = "default/linux/x86/13.0">
<#else>
    <#assign gentooProfile = "default/linux/amd64/13.0/no-multilib">
</#if>
eselect profile set ${gentooProfile}

<#if architecture == "i386">
emerge --unmerge sys-apps/module-init-tools
</#if>

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

groupadd sudo
useradd -r -m -s /bin/bash ec2-user

ln -s /etc/init.d/net.lo /etc/init.d/net.eth0

rc-update add net.eth0 default
rc-update add sshd default
rc-update add syslog-ng default
rc-update add fcron default
rc-update add ntpd default
rc-update add lvm boot
rc-update add mdraid boot

