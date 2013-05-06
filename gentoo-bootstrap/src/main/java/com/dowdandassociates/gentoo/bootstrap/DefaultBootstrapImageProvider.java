
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

public class DefaultBootstrapImageProvider extends LatestImageProvider
{
    private static Logger log = LoggerFactory.getLogger(DefaultBootstrapImageProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapImage.virtualizationType")
    private Supplier<String> virtualizationType = Suppliers.ofInstance("paravirtual");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapImage.rootDeviceType")
    private Supplier<String> rootDeviceType = Suppliers.ofInstance("ebs");

    private String architecture;

    @Inject
    public DefaultBootstrapImageProvider(AmazonEC2 ec2Client, @Named("Architecture") String architecture)
    {
        super(ec2Client);
        this.architecture = architecture;
    }

    @Override
    protected DescribeImagesRequest getRequest()
    {
        StringBuilder manifestLocation = new StringBuilder();
        
        String localVirtualizationType;
        String localArchitecture;
        String localRootDeviceType;

        manifestLocation.append("*/amzn-ami-");
        if ("hvm".equals(virtualizationType.get()))
        {
            manifestLocation.append("hvm");
            localVirtualizationType = "hvm";
            localArchitecture = "x86_64";
            localRootDeviceType = "ebs";
        }
        else
        {
            manifestLocation.append("pv");
            localVirtualizationType = "paravirtual";
            localArchitecture = architecture;
            localRootDeviceType = rootDeviceType.get();
        }
        manifestLocation.append("-????.??.?.*");

        return new DescribeImagesRequest().
                withOwners("amazon").
                withFilters(new Filter().withName("image-type").withValues("machine"),
                            new Filter().withName("virtualization-type").withValues(localVirtualizationType),
                            new Filter().withName("architecture").withValues(localArchitecture),
                            new Filter().withName("root-device-type").withValues(localRootDeviceType),
                            new Filter().withName("manifest-location").withValues(manifestLocation.toString()));

    }
}

