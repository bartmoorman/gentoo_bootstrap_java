# /etc/local.d/initialize.start

curl --silent --fail -o "/tmp/user-data" http://169.254.169.254/latest/user-data
if [ $? -eq 0 ]; then
	sleep 30 && source "/tmp/user-data" > /var/log/initialize.log 2>&1 &
	rm <#noparse>${BASH_SOURCE[0]}</#noparse>
fi
