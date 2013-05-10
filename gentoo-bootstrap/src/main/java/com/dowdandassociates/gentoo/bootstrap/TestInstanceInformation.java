
package com.dowdandassociates.gentoo.bootstrap;

import java.util.Objects;

import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;

import com.google.common.base.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TestInstanceInformation
{
    private static Logger log = LoggerFactory.getLogger(TestInstanceInformation.class);

    private Optional<Instance> instance;
    private Optional<Image> image;

    public TestInstanceInformation()
    {
        instance = Optional.absent();
        image = Optional.absent();
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

    public TestInstanceInformation withInstance(Optional<Instance> instance)
    {
        setInstance(instance);
        return this;
    }

    public TestInstanceInformation withInstance(Instance instance)
    {
        setInstance(instance);
        return this;
    }

    public Optional<Image> getImage()
    {
        return image;
    }

    public void setImage(Optional<Image> image)
    {
        if (null != image)
        {
            this.image = image;
        }
        else
        {
            this.image = Optional.absent();
        }
    }

    public void setImage(Image image)
    {
        this.image = Optional.fromNullable(image);
    }

    public TestInstanceInformation withImage(Optional<Image> image)
    {
        setImage(image);
        return this;
    }

    public TestInstanceInformation withImage(Image image)
    {
        setImage(image);
        return this;
    }
}

