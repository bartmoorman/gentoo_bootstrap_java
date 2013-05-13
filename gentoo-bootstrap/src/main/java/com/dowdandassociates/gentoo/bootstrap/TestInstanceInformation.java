/*
 *
 * TestInstanceInformation.java
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

