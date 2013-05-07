
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Image;

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.name.Named;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultKernelImageProvider extends LatestImageProvider
{
    private static Logger log = LoggerFactory.getLogger(DefaultKernelImageProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.KernelImage.bootPartition")
    private Supplier<String> bootPartition = Suppliers.ofInstance("hd0");

    private Supplier<String> architecture;

    @Inject
    public DefaultKernelImageProvider(AmazonEC2 ec2Client, @Named("Architecture") Supplier<String> architecture)
    {
        super(ec2Client);
        this.architecture = architecture;
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

