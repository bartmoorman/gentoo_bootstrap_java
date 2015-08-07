#!/bin/bash

echo "--- PREPARING ENVIRONMENT"

echo "--- Partition disk"
fdisk ${device} <<'EOF'
n
p
1


w
EOF

echo "--- Format volume"
mkfs -t ${rootfstype} ${device}1

echo "--- Create mount point"
mkdir -p ${mountPoint}

echo "--- Mount volume"
mount ${device}1 ${mountPoint}

echo "--- Download stage3"
<#if architecture == "i386">
    <#assign archDir = "x86">
    <#assign archFile = "i686">
<#else>
    <#assign archDir = "amd64">
    <#assign archFile = "amd64">
</#if>
stage3_file="$(mktemp)"
curl -sf -o "<#noparse>${stage3_file}</#noparse>" "${mirror}releases/${archDir}/autobuilds/$(curl -sf "${mirror}releases/${archDir}/autobuilds/latest-stage3-${archFile}.txt" | grep stage3-${archFile})"

echo "--- Unpack stage3"
tar xjpf "<#noparse>${stage3_file}</#noparse>" -C ${mountPoint}

echo "--- Download portage"
portage_file="$(mktemp)"
curl -sf -o "<#noparse>${portage_file}</#noparse>" "${mirror}snapshots/portage-latest.tar.bz2"

echo "--- Unpack portage"
tar xjf "<#noparse>${portage_file}</#noparse>" -C ${mountPoint}/usr

echo "--- /etc/resolv.conf (copy)"
cp -L /etc/resolv.conf ${mountPoint}/etc/resolv.conf

build_file="$(mktemp)"
cat <<'END_OF_FILE'>${mountPoint}<#noparse>${build_file}</#noparse>
<#include "/usr/local/bin/build.sh.ftl">
END_OF_FILE
chmod 755 ${mountPoint}<#noparse>${build_file}</#noparse>

mount -t proc none ${mountPoint}/proc
mount --rbind /dev ${mountPoint}/dev
mount --rbind /dev/pts ${mountPoint}/dev/pts

echo "--- chroot and start building"
chroot ${mountPoint} <#noparse>${build_file}</#noparse>

rm -fR ${mountPoint}/tmp/*
rm -fR ${mountPoint}/var/tmp/*
rm -fR ${mountPoint}/usr/portage/distfiles/*

shutdown -h now
