/*
 *
 * BootstrapSessionInformation.java
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

