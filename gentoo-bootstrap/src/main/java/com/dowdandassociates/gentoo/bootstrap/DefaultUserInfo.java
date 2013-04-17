
package com.dowdandassociates.gentoo.bootstrap;

import com.jcraft.jsch.UserInfo;

import com.netflix.governator.annotations.Configuration;
import com.netflix.governator.guice.lazy.FineGrainedLazySingleton;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@FineGrainedLazySingleton
public class DefaultUserInfo implements UserInfo
{
    private static Logger log = LoggerFactory.getLogger(DefaultUserInfo.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.UserInfo.passphrase")
    private String passphrase = null;

    @Configuration("com.dowdandassociates.gentoo.bootstrap.UserInfo.password")
    private String password = null;

    @Configuration("com.dowdandassociates.gentoo.bootstrap.UserInfo.yesNo")
    private boolean yesNo = true;

    public String getPassphrase()
    {
        return passphrase;
    }

    public String getPassword()
    {
        return password;
    }

    public boolean promptPassphrase(String message)
    {
        return (null != passphrase);
    }

    public boolean promptPassword(String message)
    {
        return (null != password);
    }

    public boolean promptYesNo(String message)
    {
        return yesNo;
    }

    public void showMessage(String message)
    {
    }
}

