# /etc/local.d/hostname.start

counter=0
timeout=5

while [ true ]; do
	if [ "<#noparse>${counter}</#noparse>" -ge "<#noparse>${timeout}</#noparse>" ]; then
		echo "Unable to determine Local IPv4!"
		exit 1
	fi

	IP="$(curl -sf http://169.254.169.254/latest/meta-data/local-ipv4)"

	if [ $? -eq 0 -a -n "<#noparse>${IP}</#noparse>" ]; then
		break
	fi

	sleep 1
	counter=$(bc <<< "<#noparse>${counter}</#noparse> + 1")
done

counter=0
timeout=5

while [ true ]; do
	if [ "<#noparse>${counter}</#noparse>" -ge "<#noparse>${timeout}</#noparse>" ]; then
		echo "Unable to determine Instance ID!"
		exit 1
	fi

	INSTANCE_ID="$(curl -sf http://169.254.169.254/latest/meta-data/instance-id)"

	if [ $? -eq 0 -a -n "<#noparse>${INSTANCE_ID}</#noparse>" ]; then
		break
	fi

	sleep 1
	counter=$(bc <<< "<#noparse>${counter}</#noparse> + 1")
done

counter=0
timeout=5

while [ true ]; do
	if [ "<#noparse>${counter}</#noparse>" -ge "<#noparse>${timeout}</#noparse>" ]; then
		echo "Unable to determine Availability Zone!"
		exit 1
	fi

	AVAILABILITY_ZONE="$(curl -sf http://169.254.169.254/latest/meta-data/placement/availability-zone)"

	if [ $? -eq 0 -a -n "<#noparse>${AVAILABILITY_ZONE}</#noparse>" ]; then
		break
	fi

	sleep 1
	counter=$(bc <<< "<#noparse>${counter}</#noparse> + 1")
done

counter=0
timeout=5

while [ true ]; do
	if [ "<#noparse>${counter}</#noparse>" -ge "<#noparse>${timeout}</#noparse>" ]; then
		echo "Unable to determine Tag:Name!"
		exit 1
	fi

	NAME="$(aws --output "text" --query "Tags[*].[Value]" --region "<#noparse>${AVAILABILITY_ZONE%?}</#noparse>" ec2 describe-tags --filters "Name=resource-id,Values=<#noparse>${INSTANCE_ID}</#noparse>" "Name=key,Values=Name")"

	if [ $? -eq 0 -a -n "<#noparse>${NAME}</#noparse>" ]; then
		break
	fi

	sleep 1
	counter=$(bc <<< "<#noparse>${counter}</#noparse> + 1")
done

sed -i -r \
-e "s|^hostname\=.*|hostname\=\"<#noparse>${NAME}</#noparse>\"|" \
/etc/conf.d/hostname

sed -i -r \
-e "s|^(127\.0\.0\.1\s+).*(localhost)$|\1<#noparse>${NAME}</#noparse>\.salesteamautomation\.com <#noparse>${NAME}</#noparse> \2|" \
/etc/hosts

sed -i -r \
-e "s|CN\=.*|CN\=<#noparse>${NAME}</#noparse>\.salesteamautomation\.com|" \
/var/qmail/control/servercert.cnf

hostname <#noparse>${NAME}</#noparse>
