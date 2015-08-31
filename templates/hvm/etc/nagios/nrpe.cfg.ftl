
command[check_cron]=/usr/lib64/nagios/plugins/check_procs -c 1: -C cron -a /usr/sbin/cron
command[check_disk]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /
command[check_dnscache]=/usr/lib64/nagios/plugins/check_procs -c 1: -C dnscache -a /usr/bin/dnscache
command[check_fail2ban]=/usr/lib64/nagios/plugins/check_procs -c 1: -C fail2ban-server -a /usr/bin/fail2ban-server
command[check_gmond]=/usr/lib64/nagios/plugins/check_procs -c 1: -C gmond -a /usr/sbin/gmond
command[check_load]=/usr/lib64/nagios/plugins/check_load -r -w 2,1.5,1 -c 4,3,2
command[check_memory]=/usr/lib64/nagios/plugins/custom/check_memory -w 20 -c 10
command[check_ntpd]=/usr/lib64/nagios/plugins/check_procs -c 1: -C ntpd -a /usr/sbin/ntpd
command[check_qmail_queue]=/usr/lib64/nagios/plugins/custom/check_qmail_queue
command[check_qmail_send]=/usr/lib64/nagios/plugins/check_procs -c 1: -C qmail-send -a qmail-send
command[check_sshd]=/usr/lib64/nagios/plugins/check_procs -c 1: -C sshd -a /usr/sbin/sshd
command[check_svscan]=/usr/lib64/nagios/plugins/check_procs -c 1: -C svscan -a /usr/bin/svscan
command[check_syslog]=/usr/lib64/nagios/plugins/check_procs -c 1: -C syslog-ng -a /usr/sbin/syslog-ng
command[check_time]=/usr/lib64/nagios/plugins/check_ntp_time -H %HOSTNAME_PREFIX%monitor1 -w 5 -c 10
