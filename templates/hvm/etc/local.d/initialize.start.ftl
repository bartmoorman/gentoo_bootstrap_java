# /etc/local.d/initialize.start

curl -sf -o "/tmp/user-data" http://169.254.169.254/latest/user-data
if [ $? -eq 0 ]; then
	sleep 30 && bash "/tmp/user-data" &> /var/log/initialize.log &
	rm <#noparse>${BASH_SOURCE[0]}</#noparse>
fi
