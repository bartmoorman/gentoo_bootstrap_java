# /etc/local.d/initialize.start
user_data_file="$(mktemp)"
curl -sf -o "<#noparse>${user_data_file}</#noparse>" "http://169.254.169.254/latest/user-data" || exit 1
sleep 30 && bash "<#noparse>${user_data_file}</#noparse>" &> /var/log/initialize.log &
rm <#noparse>${BASH_SOURCE[0]}</#noparse>
