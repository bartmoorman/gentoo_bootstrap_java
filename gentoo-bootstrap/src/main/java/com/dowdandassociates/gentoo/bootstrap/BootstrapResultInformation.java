/*
 *
 * BootstrapResultInformation.java
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

import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BootstrapResultInformation
{
    private static Logger log = LoggerFactory.getLogger(BootstrapResultInformation.class);

    private BootstrapInstanceInformation instanceInfo;
    private Optional<Integer> exitStatus;

    public BootstrapResultInformation()
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

    public BootstrapResultInformation withInstanceInfo(BootstrapInstanceInformation instanceInfo)
    {
        setInstanceInfo(instanceInfo);
        return this;
    }

    public Optional<Integer> getExitStatus()
    {
        return exitStatus;
    }

    public void setExitStatus(Optional<Integer> exitStatus)
    {
        if (null == exitStatus)
        {
            this.exitStatus = Optional.absent();
        }
        else
        {
            this.exitStatus = exitStatus;
        }
    }

    public void setExitStatus(Integer exitStatus)
    {
        this.exitStatus = Optional.fromNullable(exitStatus);
    }

    public BootstrapResultInformation withExitStatus(Optional<Integer> exitStatus)
    {
        setExitStatus(exitStatus);
        return this;
    }

    public BootstrapResultInformation withExitStatus(Integer exitStatus)
    {
        setExitStatus(exitStatus);
        return this;
    }
}

