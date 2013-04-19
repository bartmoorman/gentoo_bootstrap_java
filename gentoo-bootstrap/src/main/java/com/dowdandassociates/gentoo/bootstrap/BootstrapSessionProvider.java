
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.model.Instance;

import com.google.common.base.Optional;
import com.google.common.base.Strings;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.name.Named;

import com.jcraft.jsch.JSch;
import com.jcraft.jsch.UserInfo;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BootstrapSessionProvider extends AbstractSessionProvider
{
    private static Logger log = LoggerFactory.getLogger(BootstrapSessionProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapSession.user")
    private Supplier<String> user = Suppliers.ofInstance("ec2-user");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapSession.port")
    private Supplier<Integer> port = Suppliers.ofInstance(22);

    private Optional<JSch> jsch;
    private Optional<Instance> instance;
    private UserInfo userInfo;

    @Inject
    public BootstrapSessionProvider(Optional<JSch> jsch, @Named("Bootstrap Instance") Optional<Instance> instance, UserInfo userInfo)
    {
        this.jsch = jsch;
        this.instance = instance;
        this.userInfo = userInfo;
    }

    @Override
    protected Optional<JSch> getJSch()
    {
        return jsch;
    }

    @Override
    protected String getUser()
    {
        return user.get();
    }

    @Override
    protected Optional<String> getHost()
    {
        if (instance.isPresent())
        {
            return Optional.fromNullable(Strings.emptyToNull(instance.get().getPublicDnsName()));
        }
        else
        {
            return Optional.absent();
        }
    }

    @Override
    protected int getPort()
    {
        return port.get();
    }

    @Override
    protected UserInfo getUserInfo()
    {
        return userInfo;
    }
}

