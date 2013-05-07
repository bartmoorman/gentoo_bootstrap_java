
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BootstrapResultInformation
{
    private static Logger log = LoggerFactory.getLogger(BootstrapResultInformation.class);

    private Optional<Instance> instance;
    private Optional<Volume> volume;
    private Optional<Integer> exitStatus;

    public BootstrapResultInformation()
    {
    }

    public Optional<Instance> getInstance()
    {
        return instance;
    }

    public void setInstance(Optional<Instance> instance)
    {
        if (null == instance)
        {
            this.instance = Optional.absent();
        }
        else
        {
            this.instance = instance;
        }
    }

    public void setInstance(Instance instance)
    {
        this.instance = Optional.fromNullable(instance);
    }

    public BootstrapResultInformation withInstance(Optional<Instance> instance)
    {
        setInstance(instance);
        return this;
    }

    public BootstrapResultInformation withInstance(Instance instance)
    {
        setInstance(instance);
        return this;
    }

    public Optional<Volume> getVolume()
    {
        return volume;
    }

    public void setVolume(Optional<Volume> volume)
    {
        if (null == volume)
        {
            this.volume = Optional.absent();
        }
        else
        {
            this.volume = volume;
        }
    }

    public void setVolume(Volume volume)
    {
        this.volume = Optional.fromNullable(volume);
    }

    public BootstrapResultInformation withVolume(Optional<Volume> volume)
    {
        setVolume(volume);
        return this;
    }

    public BootstrapResultInformation withVolume(Volume volume)
    {
        setVolume(volume);
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

