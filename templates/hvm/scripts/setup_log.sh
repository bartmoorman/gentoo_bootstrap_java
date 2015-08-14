#!/bin/bash
ip="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
name="$(hostname)"
iam_role="$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)"
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

echo "Not implementing as of 08/03/2015"
exit 1

curl -sf "http://eu1iec1ns1:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || curl -sf "http://eu1iec1ns2:8053?type=A&name=${name}&domain=salesteamautomation.com&address=${ip}" || exit 1
