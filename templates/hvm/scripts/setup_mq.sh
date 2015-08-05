#!/bin/bash
while getopts "p:b:" OPTNAME; do
	case $OPTNAME in
		p)
			echo "Peer: ${OPTARG}"
			peer="${OPTARG}"
			;;
		b)
			echo "Bucket Name: ${OPTARG}"
			bucket_name="${OPTARG}"
			;;
	esac
done

if [ -z "${peer}" ]; then
	echo "Usage: ${BASH_SOURCE[0]} -p peer_name:peer_ip -b bucket_name"
	exit 1
fi

scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"
