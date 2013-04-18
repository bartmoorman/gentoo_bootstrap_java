
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Image;

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultKernelImageProvider extends LatestImageProvider
{
    private static Logger log = LoggerFactory.getLogger(DefaultKernelImageProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.KernelImage.architecture")
    private Supplier<String> architecture = Suppliers.ofInstance("x86_64");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.KernelImage.bootPartition")
    private Supplier<String> bootPartition = Suppliers.ofInstance("hd0");

    @Inject
    public DefaultKernelImageProvider(AmazonEC2 ec2Client)
    {
        super(ec2Client);
    }

    @Override
    protected DescribeImagesRequest getRequest()
    {
        StringBuilder manifestLocation = new StringBuilder();
        
        manifestLocation.append("*pv-grub-");
        manifestLocation.append(bootPartition.get());
        manifestLocation.append("_*");

        return new DescribeImagesRequest().
                withOwners("amazon").
                withFilters(new Filter().withName("image-type").withValues("kernel"),
                            new Filter().withName("architecture").withValues(architecture.get()),
                            new Filter().withName("manifest-location").withValues(manifestLocation.toString()));
    }
}

