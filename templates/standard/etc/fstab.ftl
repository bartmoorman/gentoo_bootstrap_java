/dev/xvda1  /           ${rootfstype}   defaults        1   1
<#if architecture == "i386">
/dev/xvda3  none        swap            sw              0   0
</#if>
none        /dev/pts    devpts          gid=5,mode=620  0   0
none        /dev/shm    tmpfs           defaults        0   0
none        /proc       proc            defaults        0   0
none        /sys        sysfs           defaults        0   0

