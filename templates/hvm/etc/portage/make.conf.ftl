<#if architecture == "i386">
CFLAGS="-O2 -march=i686 -mno-tls-direct-seg-refs -pipe"
CHOST="i686-pc-linux-gnu"
<#else>
CFLAGS="-O2 -pipe"
CHOST="x86_64-pc-linux-gnu"
USE="mmx sse sse2"
</#if>
CXXFLAGS="<#noparse>${CFLAGS}</#noparse>"
MAKEOPTS="-j3"
EMERGE_DEFAULT_OPTS="--jobs=2 --load-average=3.0"
