
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SimpleBootstrapImageProvider extends SimpleImageProvider
{
    private static Logger log = LoggerFactory.getLogger(SimpleBootstrapImageProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapImage.imageId")
    private Supplier<String> imageId = Suppliers.ofInstance(null);

    @Inject
    public SimpleBootstrapImageProvider(AmazonEC2 ec2Client)
    {
        super(ec2Client);
    }

    @Override
    protected String getImageId()
    {
        return imageId.get();
    }
}

