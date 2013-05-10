# /etc/local.d/public-keys.start

wget -q -O /tmp/my-key http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key
if [ $? -eq 0 ] ; then
    [ ! -e /home/ec2-user ] && cp -r /etc/skel /home/ec2-user && chown -R ec2-user /home/ec2-user && chgrp -R ec2-user /home/ec2-user
    if [ ! -d /home/ec2-user/.ssh ] ; then
        mkdir -p /home/ec2-user/.ssh
        chmod 700 /home/ec2-user/.ssh
        chown ec2-user /home/ec2-user/.ssh
        chgrp ec2-user /home/ec2-user/.ssh
    fi
    cat /tmp/my-key > /home/ec2-user/.ssh/authorized_keys
    chmod 600 /home/ec2-user/.ssh/authorized_keys
    chown ec2-user /home/ec2-user/.ssh/authorized_keys
    chgrp ec2-user /home/ec2-user/.ssh/authorized_keys
    rm /tmp/my-key
fi

