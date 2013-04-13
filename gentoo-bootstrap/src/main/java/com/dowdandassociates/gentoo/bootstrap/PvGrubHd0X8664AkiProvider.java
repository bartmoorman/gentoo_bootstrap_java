
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.Filter;

import com.google.inject.Inject;

public class PvGrubHd0X8664AkiProvider extends LatestImageProvider
{
    @Inject
    public PvGrubHd0X8664AkiProvider(AmazonEC2 ec2Client)
    {
        super(
                ec2Client,
                new DescribeImagesRequest().
                        withOwners("amazon").
                        withFilters(new Filter().withName("image-type").withValues("kernel"),
                                    new Filter().withName("architecture").withValues("x86_64"),
                                    new Filter().withName("manifest-location").withValues("*pv-grub-hd0_*")));
    }
}

