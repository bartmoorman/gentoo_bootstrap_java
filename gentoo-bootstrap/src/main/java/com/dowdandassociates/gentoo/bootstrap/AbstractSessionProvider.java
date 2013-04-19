
package com.dowdandassociates.gentoo.bootstrap;

import com.google.common.base.Optional;

import com.google.inject.Provider;

import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.UserInfo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractSessionProvider implements Provider<Optional<Session>>
{
    private static Logger log = LoggerFactory.getLogger(AbstractSessionProvider.class);

    public Optional<Session> get()
    {
        log.info("Get Session");
        try
        {
            Optional<JSch> jsch = getJSch();
            if (null == jsch || !jsch.isPresent())
            {
                return Optional.absent();
            }

            Optional<String> host = getHost();
            if (null == host || !host.isPresent())
            {
                return Optional.absent();
            }

            Session session = jsch.get().getSession(getUser(), host.get(), getPort());
            session.setUserInfo(getUserInfo());
            session.connect();
            return Optional.of(session);
        }
        catch (JSchException jse)
        {
            log.error(jse.getMessage(), jse);
            return Optional.absent();
        }
    }

    protected abstract Optional<JSch> getJSch();
    protected abstract String getUser();
    protected abstract Optional<String> getHost();
    protected abstract int getPort();
    protected abstract UserInfo getUserInfo();
}

