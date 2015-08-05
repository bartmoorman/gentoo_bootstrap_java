# /etc/local.d/initialize.start
filename="$(mktemp)"
curl -sf -o "<#noparse>${filename}</#noparse>" "http://169.254.169.254/latest/user-data" || exit 1
sleep 30 && bash "<#noparse>${filename}</#noparse>" &> /var/log/initialize.log &
rm <#noparse>${BASH_SOURCE[0]}</#noparse>
