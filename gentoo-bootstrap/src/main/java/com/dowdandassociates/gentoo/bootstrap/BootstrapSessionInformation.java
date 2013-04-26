
package com.dowdandassociates.gentoo.bootstrap;

import com.google.common.base.Optional;

import com.jcraft.jsch.Session;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BootstrapSessionInformation
{
    private static Logger log = LoggerFactory.getLogger(BootstrapSessionInformation.class);

    private BootstrapInstanceInformation instanceInfo;
    private Optional<Session> session;

    public BootstrapSessionInformation()
    {
    }

    public BootstrapInstanceInformation getInstanceInfo()
    {
        return instanceInfo;
    }

    public void setInstanceInfo(BootstrapInstanceInformation instanceInfo)
    {
        this.instanceInfo = instanceInfo;
    }

    public BootstrapSessionInformation withInstanceInfo(BootstrapInstanceInformation instanceInfo)
    {
        setInstanceInfo(instanceInfo);
        return this;
    }

    public Optional<Session> getSession()
    {
        return session;
    }

    public void setSession(Optional<Session> session)
    {
        if (null != session)
        {
            this.session = session;
        }
        else
        {
            this.session = Optional.absent();
        }
    }

    public BootstrapSessionInformation withSession(Optional<Session> session)
    {
        setSession(session);
        return this;
    }
}

