
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Image;

import com.google.inject.Inject;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultKernelImageProvider extends LatestImageProvider
{
    private static Logger log = LoggerFactory.getLogger(DefaultKernelImageProvider.class);

    private ImageInformation imageInfo;

    @Inject
    public DefaultKernelImageProvider(AmazonEC2 ec2Client, ImageInformation imageInfo)
    {
        super(ec2Client);
        this.imageInfo = imageInfo;
    }

    @Override
    protected DescribeImagesRequest getRequest()
    {
        StringBuilder manifestLocation = new StringBuilder();
        
        manifestLocation.append("*pv-grub-");
        manifestLocation.append(imageInfo.getBootPartition());
        manifestLocation.append("_*");

        return new DescribeImagesRequest().
                withOwners("amazon").
                withFilters(new Filter().withName("image-type").withValues("kernel"),
                            new Filter().withName("architecture").withValues(imageInfo.getArchitecture()),
                            new Filter().withName("manifest-location").withValues(manifestLocation.toString()));
    }
}

