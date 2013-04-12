
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.Filter;

import com.google.inject.Provider;

public class PvGrubHd0X8664AkiProvider implements Provider<DescribeImagesRequest>
{
    public DescribeImagesRequest get()
    {
        return new DescribeImagesRequest().
                withOwners("amazon").
                withFilters(new Filter().withName("image-type").withValues("kernel"),
                            new Filter().withName("architecture").withValues("x86_64"),
                            new Filter().withName("manifest-location").withValues("*pv-grub-hd0_*"));
    }
}

