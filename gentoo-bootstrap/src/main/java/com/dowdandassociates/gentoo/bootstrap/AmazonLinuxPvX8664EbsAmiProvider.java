
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.Filter;

import com.google.inject.Provider;

public class AmazonLinuxPvX8664EbsAmiProvider implements Provider<DescribeImagesRequest>
{
    public DescribeImagesRequest get()
    {
        return new DescribeImagesRequest().
                withOwners("amazon").
                withFilters(new Filter().withName("image-type").withValues("machine"),
                            new Filter().withName("virtualization-type").withValues("paravirtual"),
                            new Filter().withName("architecture").withValues("x86_64"),
                            new Filter().withName("root-device-type").withValues("ebs"),
                            new Filter().withName("manifest-location").withValues("amazon/amzn-ami-pv-????.??.?.x86_64-ebs"));

    }
}

