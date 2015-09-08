[sshd]
enabled  = true
filter   = sshd
action   = hostsdeny[daemon_list=sshd]
logpath  = /var/log/messages
ignoreip = 10.0.0.0/8
bantime  = 31536000
findtime = 600
maxretry = 5
