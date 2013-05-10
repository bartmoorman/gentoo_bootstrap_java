#!/bin/bash

echo "Format volume"
mkfs -t ${rootfstype} ${device}

echo "Create mount point"
mkdir -p ${mountPoint}

echo "Mount volume"
mount ${device} ${mountPoint}

echo "Download stage3"
<#if architecture == "i386">
    <#assign archDir = "x86">
    <#assign archFile = "i686">
<#else>
    <#assign archDir = "amd64">
    <#assign archFile = "amd64">
</#if>
curl --silent -o /tmp/stage3.tar.bz2 "${mirror}releases/${archDir}/autobuilds/`curl --silent "${mirror}releases/${archDir}/autobuilds/latest-stage3-${archFile}.txt" | grep stage3-${archFile}`"

echo "Download portage"
curl --silent -o /tmp/portage.tar.bz2 "${mirror}snapshots/portage-latest.tar.bz2"

echo "Unpack stage3"
tar -xjpf /tmp/stage3.tar.bz2 -C ${mountPoint}

echo "Unpack portage"
tar -xjf /tmp/portage.tar.bz2 -C ${mountPoint}/usr

echo "Setup files"

echo "/etc/resolv.conf"
cp -L /etc/resolv.conf ${mountPoint}/etc/resolv.conf

echo "/tmp/build.sh"
cat <<'END_OF_FILE'>/tmp/build.sh
<#include "/build.sh.ftl">
END_OF_FILE
chmod 755 /tmp/build.sh

mount -t proc none ${mountPoint}/proc
mount --rbind /dev ${mountPoint}/dev
mount --rbind /dev/pts ${mountPoint}/dev/pts

chroot ${mountPoint} /tmp/build.sh

rm -fR ${mountPoint}/tmp/*
rm -fR ${mountPoint}/var/tmp/*
rm -fR ${mountPoint}/usr/portage/distfiles/*

shutdown -h now

