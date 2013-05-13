/*
 *
 * DefaultUserInfo.java
 *
 *-----------------------------------------------------------------------------
 * Copyright 2013 Dowd and Associates
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *-----------------------------------------------------------------------------
 *
 */

package com.dowdandassociates.gentoo.bootstrap;

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

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
    private Supplier<String> passphrase = Suppliers.ofInstance(null);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.UserInfo.password")
    private Supplier<String> password = Suppliers.ofInstance(null);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.UserInfo.yesNo")
    private Supplier<Boolean> yesNo = Suppliers.ofInstance(true);

    public String getPassphrase()
    {
        return passphrase.get();
    }

    public String getPassword()
    {
        return password.get();
    }

    public boolean promptPassphrase(String message)
    {
        return (null != getPassphrase());
    }

    public boolean promptPassword(String message)
    {
        return (null != getPassword());
    }

    public boolean promptYesNo(String message)
    {
        return yesNo.get();
    }

    public void showMessage(String message)
    {
    }
}

