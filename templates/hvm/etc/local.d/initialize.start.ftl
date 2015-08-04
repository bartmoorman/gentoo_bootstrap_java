# /etc/local.d/initialize.start

curl -sf -o "/tmp/user-data" "http://169.254.169.254/latest/user-data" || exit 1
sleep 30 && bash "/tmp/user-data" &> /var/log/initialize.log &
rm <#noparse>${BASH_SOURCE[0]}</#noparse>
