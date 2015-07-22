# /etc/local.d/hostname.start

INSTANCE_ID="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
if [ -z "${INSTANCE_ID}" ]; then
	echo "Unable to determine Instance ID!"
	exit 1
fi
AVAILABILITY_ZONE="$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)"
if [ -z "${AVAILABILITY_ZONE}" ]; then
	echo "Unable to determine Availability Zone!"
	exit 1
fi
NAME="$(aws ec2 describe-tags --region <#noparse>${AVAILABILITY_ZONE%?}</#noparse> --output text --filter "Name=resource-id,Values=<#noparse>${INSTANCE_ID}</#noparse>" "Name=key,Values=Name" --query "Tags[*].[Value]")"
if [ -z "${NAME}" ]; then
	echo "Unable to determine Tag:Name!"
	exit 1
fi

sed -i -r \
-e "s|^hostname=.*|hostname=\"<#noparse>${NAME}</#noparse>\"|" \
/etc/conf.d/hostname

sed -i -r \
-e "s|^(127.0.0.1\s+).*(localhost)|\1<#noparse>${NAME}</#noparse>.salesteamautomation.com <#noparse>${NAME}</#noparse> \2|" \
/etc/hosts

sed -i -r \
-e "s|CN=.*|CN=<#noparse>${NAME}</#noparse>.salesteamautomation.com|" \
/var/qmail/control/servercert.cnf

hostname ${NAME}
