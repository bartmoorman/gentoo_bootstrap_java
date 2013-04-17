
package com.dowdandassociates.gentoo.bootstrap;

import com.google.inject.Provider;

import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.UserInfo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractSessionProvider implements Provider<Session>
{
    private static Logger log = LoggerFactory.getLogger(AbstractSessionProvider.class);

    public Session get()
    {
        try
        {
            Session session = getJSch().getSession(getUser(), getHost(), getPort());
            session.setUserInfo(getUserInfo());
            session.connect();
            return session;
        }
        catch (JSchException jse)
        {
            log.error(jse.getMessage(), jse);
            return null;
        }
    }

    protected abstract JSch getJSch();
    protected abstract String getUser();
    protected abstract String getHost();
    protected abstract int getPort();
    protected abstract UserInfo getUserInfo();
}

