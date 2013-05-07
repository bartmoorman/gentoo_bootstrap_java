
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

