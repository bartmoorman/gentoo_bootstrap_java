
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.model.Instance;

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
    private String user = "ec2-user";

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapSession.port")
    private int port = 22;

    private JSch jsch;
    private Instance instance;
    private UserInfo userInfo;

    @Inject
    public BootstrapSessionProvider(JSch jsch, @Named("Bootstrap Instance") Instance instance, UserInfo userInfo)
    {
        this.jsch = jsch;
        this.instance = instance;
        this.userInfo = userInfo;
    }

    @Override
    protected JSch getJSch()
    {
        return jsch;
    }

    @Override
    protected String getUser()
    {
        return user;
    }

    @Override
    protected String getHost()
    {
        return instance.getPublicDnsName();
    }

    @Override
    protected int getPort()
    {
        return port;
    }

    @Override
    protected UserInfo getUserInfo()
    {
        return userInfo;
    }
}

