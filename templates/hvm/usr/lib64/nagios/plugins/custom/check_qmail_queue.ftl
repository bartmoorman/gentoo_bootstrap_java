#!/bin/bash
warning=500
critical=750

cd /var/qmail/

messagedirs=$(echo queue/mess/* | wc -w)
messagefiles=$(find queue/mess/* -print | wc -w)
messages=$(bc <<< "<#noparse>${messagefiles}</#noparse> - <#noparse>${messagedirs}</#noparse>")

if [ $(bc <<< "<#noparse>${messages}</#noparse> > <#noparse>${critical}</#noparse>") -eq 1 ]
then
	echo CRITICAL: <#noparse>${messages}</#noparse> messages in queue
	exit 2
elif [ $(bc <<< "<#noparse>${messages}</#noparse> > <#noparse>${warning}</#noparse>") -eq 1 ]
then
	echo WARNING: <#noparse>${messages}</#noparse> messages in queue
	exit 1
else
	echo OK: <#noparse>${messages}</#noparse> messages in queue
	exit 0
fi
