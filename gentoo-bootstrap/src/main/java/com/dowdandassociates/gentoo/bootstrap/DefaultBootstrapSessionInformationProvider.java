
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.model.Instance;

import com.google.common.base.Optional;
import com.google.common.base.Strings;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;
import com.google.inject.name.Named;

import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.UserInfo;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultBootstrapSessionInformationProvider implements Provider<BootstrapSessionInformation>
{
    private static Logger log = LoggerFactory.getLogger(DefaultBootstrapSessionInformationProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapSession.user")
    private Supplier<String> user = Suppliers.ofInstance("ec2-user");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapSession.port")
    private Supplier<Integer> port = Suppliers.ofInstance(22);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapSession.waitToConnect")
    private Supplier<Long> sleep = Suppliers.ofInstance(0L);

    private Optional<JSch> jsch;
    private UserInfo userInfo;
    private BootstrapInstanceInformation instanceInfo;

    @Inject
    public DefaultBootstrapSessionInformationProvider(Optional<JSch> jsch, UserInfo userInfo, BootstrapInstanceInformation instanceInfo)
    {
        this.jsch = jsch;
        this.userInfo = userInfo;
        this.instanceInfo = instanceInfo;
    }

    @Override
    public BootstrapSessionInformation get()
    {
        return new BootstrapSessionInformation().
                withInstanceInfo(instanceInfo).
                withSession(getSession());
    }

    private Optional<Session> getSession()
    {
        try
        {
            if (null == jsch || !jsch.isPresent())
            {
                return Optional.absent();
            }

            Optional<String> host = getHost();
            if (!host.isPresent())
            {
                return Optional.absent();
            }

            if (sleep.get() > 0)
            {
                log.info("Waiting " + sleep.get() + " ms");
                Thread.sleep(sleep.get());
            }

            Session session = jsch.get().getSession(user.get(), host.get(), port.get());
            session.setUserInfo(userInfo);
            session.connect();
            return Optional.of(session);
        }
        catch (InterruptedException | JSchException e)
        {
            log.error(e.getMessage(), e);
            return Optional.absent();
        }
    }

    private Optional<String> getHost()
    {
        if (null == instanceInfo)
        {
            return Optional.absent();
        }

        Optional<Instance> instance = instanceInfo.getInstance();

        if (instance.isPresent())
        {
            return Optional.fromNullable(Strings.emptyToNull(instance.get().getPublicDnsName()));
        }
        else
        {
            return Optional.absent();
        }
    }
}

