#!/bin/bash
if [ -f "/var/lib/ganglia/rrds/.keep_sys-cluster_ganglia-0" ]; then
	rsync -avzq --del /var/lib/ganglia/rrds/ /var/lib/ganglia/rrds-disk/
fi
