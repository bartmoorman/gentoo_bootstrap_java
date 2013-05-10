
package com.dowdandassociates.gentoo.bootstrap;

import com.google.common.base.Optional;

import com.jcraft.jsch.Session;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TestSessionInformation
{
    private static Logger log = LoggerFactory.getLogger(TestSessionInformation.class);

    private TestInstanceInformation instanceInfo;
    private Optional<Session> session;

    public TestSessionInformation()
    {
    }

    public TestInstanceInformation getInstanceInfo()
    {
        return instanceInfo;
    }

    public void setInstanceInfo(TestInstanceInformation instanceInfo)
    {
        this.instanceInfo = instanceInfo;
    }

    public TestSessionInformation withInstanceInfo(TestInstanceInformation instanceInfo)
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

    public TestSessionInformation withSession(Optional<Session> session)
    {
        setSession(session);
        return this;
    }
}

