
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Image;

import com.google.inject.Inject;
import com.google.inject.name.Named;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultBootstrapImageProvider extends LatestImageProvider
{
    private static Logger log = LoggerFactory.getLogger(DefaultBootstrapImageProvider.class);

    private ImageInformation imageInfo;

    @Inject
    public DefaultBootstrapImageProvider(AmazonEC2 ec2Client, ImageInformation imageInfo)
    {
        super(ec2Client);
        this.imageInfo = imageInfo;
    }

    @Override
    protected DescribeImagesRequest getRequest()
    {
        StringBuilder manifestLocation = new StringBuilder();
        
        manifestLocation.append("*/amzn-ami-");
        if ("hvm".equals(imageInfo.getVirtualizationType()))
        {
            manifestLocation.append("hvm");
        }
        else
        {
            manifestLocation.append("pv");
        }
        manifestLocation.append("-????.??.?.*");

        return new DescribeImagesRequest().
                withOwners("amazon").
                withFilters(new Filter().withName("image-type").withValues("machine"),
                            new Filter().withName("virtualization-type").withValues(imageInfo.getVirtualizationType()),
                            new Filter().withName("architecture").withValues(imageInfo.getArchitecture()),
                            new Filter().withName("root-device-type").withValues(imageInfo.getRootDeviceType()),
                            new Filter().withName("manifest-location").withValues(manifestLocation.toString()));

    }
}

