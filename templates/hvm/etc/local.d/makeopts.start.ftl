# /etc/local.d/makeopts.start

LAST_PROCESSOR="`grep "^processor" /proc/cpuinfo | tail -n 1`"
CORES="`echo <#noparse>${LAST_PROCESSOR}</#noparse> | awk '{ print $3 + 1 }'`"
THREADS="`echo <#noparse>${LAST_PROCESSOR}</#noparse> | awk '{ print $3 + 2 }'`"
cp /etc/portage/make.conf /etc/portage/make.conf.old
sed \
-e "s/MAKEOPTS=.*/MAKEOPTS=\"-j<#noparse>${THREADS}</#noparse>\"/g" \
-e "s/EMERGE_DEFAULT_OPTS=.*/EMERGE_DEFAULT_OPTS=\"--jobs=<#noparse>${CORES}</#noparse> --load-average=<#noparse>${THREADS}</#noparse>.0\"/g" \
/etc/portage/make.conf.old \
> /etc/portage/make.conf
