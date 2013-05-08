
package com.dowdandassociates.gentoo.bootstrap;

import java.util.Objects;

import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BootstrapInstanceInformation
{
    private static Logger log = LoggerFactory.getLogger(BootstrapInstanceInformation.class);

    private Optional<Instance> instance;
    private Optional<Volume> volume;
    private BlockDeviceInformation device;

    public BootstrapInstanceInformation()
    {
        instance = Optional.absent();
        volume = Optional.absent();
    }

    public Optional<Instance> getInstance()
    {
        return instance;
    }

    public void setInstance(Optional<Instance> instance)
    {
        if (null != instance)
        {
            this.instance = instance;
        }
        else
        {
            this.instance = Optional.absent();
        }
    }

    public void setInstance(Instance instance)
    {
        this.instance = Optional.fromNullable(instance);
    }

    public BootstrapInstanceInformation withInstance(Optional<Instance> instance)
    {
        setInstance(instance);
        return this;
    }

    public BootstrapInstanceInformation withInstance(Instance instance)
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
        if (null != volume)
        {
            this.volume = volume;
        }
        else
        {
            this.volume = Optional.absent();
        }
    }

    public void setVolume(Volume volume)
    {
        this.volume = Optional.fromNullable(volume);
    }

    public BootstrapInstanceInformation withVolume(Optional<Volume> volume)
    {
        setVolume(volume);
        return this;
    }

    public BootstrapInstanceInformation withVolume(Volume volume)
    {
        setVolume(volume);
        return this;
    }

    @Override
    public boolean equals(Object other)
    {
        if (this == other)
        {
            return true;
        }

        if (!(other instanceof BootstrapInstanceInformation))
        {
            return false;
        }

        final BootstrapInstanceInformation info = (BootstrapInstanceInformation)other;

        if (!getInstance().equals(info.getInstance()))
        {
            return false;
        }

        if (!getVolume().equals(info.getVolume()))
        {
            return false;
        }

        return true;
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(getInstance(), getVolume());
    }
}

