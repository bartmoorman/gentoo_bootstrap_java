# $Id: check_mem,v 1.3 2008/09/17 21:47:03 nagios Exp nagios $
#
# $Log: check_mem,v $
# Revision 1.3  2008/09/17 21:47:03  nagios
# dropped free in favor of using /proc/meminfo
#
# Revision 1.2  2008/09/17 21:00:24  nagios
# added usage statement and input validation from http://www.nagiosexchange.org/cgi-bin/page.cgi?g=2099.html;d=1
# respects to the author
#
# Revision 1.1  2008/09/17 20:57:38  nagios
# Initial revision
#
# This plugin excludes the system cache and buffer, because on systems with stable memory
# usage it is perfectly normal for system cache to fill in all available memory
# (most of it can be freed at any time if applications requires it).
# Please keep a margin for system cache and buffers when setting thresholds.
#
#!/bin/bash
USAGE="`basename $0` [-w|--warning]<percent free> [-c|--critical]<percent free>"
THRESHOLD_USAGE="WARNING threshold must be greater than CRITICAL: `basename $0` $*"

# print usage
if [[ $# -lt 4 ]]
then
	echo ""
	echo "Wrong Syntax: `basename $0` $*"
	echo ""
	echo "Usage: $USAGE"
	echo ""
	exit 0
fi
# read input
while [[ $# -gt 0 ]]
  do
        case "$1" in
               -w|--warning)
               shift
               warning=$1
        ;;
               -c|--critical)
               shift
               critical=$1
        ;;
        esac
        shift
  done
# verify input
if [[ $warning -eq $critical || $warning -lt $critical ]]
then
	echo ""
	echo "$THRESHOLD_USAGE"
	echo ""
        echo "Usage: $USAGE"
	echo ""
        exit 0
fi

# Total physical memory
#total=`cat /proc/meminfo |head -n 1 |tail -n 1| gawk '{print $2}'`
total=`cat /proc/meminfo | grep ^MemTotal | awk '{print $2}'`

# Free physical memory
#free=`cat /proc/meminfo |head -n 2 |tail -n 1| gawk '{print $2}'`
free=`cat /proc/meminfo | grep ^MemFree | awk '{print $2}'`

# Buffers
#buffers=`cat /proc/meminfo |head -n 3 |tail -n 1| gawk '{print $2}'`
buffers=`cat /proc/meminfo | grep ^Buffers | awk '{print $2}'`

# Cached
#cached=`cat /proc/meminfo |head -n 4 |tail -n 1| gawk '{print $2}'`
cached=`cat /proc/meminfo | grep ^Cached | awk '{print $2}'`

kernel=`uname -r | cut -d- -f1 | sed 's/\.//'`

if [[ `bc <<< "$kernel >= 26.19"` -eq 1 ]]
then
	# Slab Reclaimable
	slab=`cat /proc/meminfo | grep ^SReclaimable | awk '{print $2}'`
else
	# Slab
	slab=`cat /proc/meminfo | grep ^Slab | awk '{print $2}'`
fi

#Available physical memory
available=`echo "$free+$buffers+$cached+$slab" | bc`

# make it into % percent free = ((free mem / total mem) * 100)
percent=`echo "scale=2; $available/$total*100" | bc`

#echo $total
#echo $free
#echo $buffers
#echo $cached
#echo $available
#echo $percent

#echo $critical
#echo $warning

#echo `echo "$percent <=  $critical"|bc`
#echo `echo "$percent <=  $warning"|bc`
#echo `echo "$percent >  $warning"|bc`

if [[ "`echo "$percent <=  $critical"|bc`" -eq 1 ]]
	then
		echo "CRITICAL: $available KB ($percent%) Free Memory"
		exit 2
fi
if [[ "`echo "$percent <=  $warning"|bc`" -eq 1 ]]
        then
                echo "WARNING: $available KB ($percent%) Free Memory"
                exit 1
fi
if [[ "`echo "$percent >  $warning"|bc`" -eq 1 ]]
        then
                echo "OK: $available KB ($percent%) Free Memory"
                exit 0
fi
