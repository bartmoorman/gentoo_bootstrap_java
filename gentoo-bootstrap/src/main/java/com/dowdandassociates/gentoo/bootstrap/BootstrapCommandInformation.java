/*
 *
 * BootstrapCommandInformation.java
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

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BootstrapCommandInformation
{
    private static Logger log = LoggerFactory.getLogger(BootstrapCommandInformation.class);

    private BootstrapSessionInformation sessionInfo;
    private Optional<String> command;

    public BootstrapCommandInformation()
    {
    }

    public BootstrapSessionInformation getSessionInfo()
    {
        return sessionInfo;
    }

    public void setSessionInfo(BootstrapSessionInformation sessionInfo)
    {
        this.sessionInfo = sessionInfo;
    }

    public BootstrapCommandInformation withSessionInfo(BootstrapSessionInformation sessionInfo)
    {
        setSessionInfo(sessionInfo);
        return this;
    }

    public Optional<String> getCommand()
    {
        return command;
    }

    public void setCommand(Optional<String> command)
    {
        if (null == command)
        {
            this.command = Optional.absent();
        }
        else
        {
            this.command = command;
        }
    }

    public void setCommand(String command)
    {
        this.command = Optional.fromNullable(command);
    }

    public BootstrapCommandInformation withCommand(Optional<String> command)
    {
        setCommand(command);
        return this;
    }

    public BootstrapCommandInformation withCommand(String command)
    {
        setCommand(command);
        return this;
    }
}

