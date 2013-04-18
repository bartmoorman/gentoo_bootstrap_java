
package com.dowdandassociates.gentoo.bootstrap;

import javax.annotation.PostConstruct;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Image;

import com.google.inject.Inject;

import com.netflix.governator.annotations.Configuration;
import com.netflix.governator.guice.lazy.FineGrainedLazySingleton;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@FineGrainedLazySingleton
public class LatestKernelImageInformation
        extends AbstractLatestImageInformation
        implements KernelImageInformation
{
    private static Logger log = LoggerFactory.getLogger(LatestKernelImageInformation.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.KernelImageInformation.architecture")
    private String architecture = "x86_64";

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapImageInformation.bootPartition")
    private String bootPartition = "hd0";

    private Image image;

    @Inject
    public LatestKernelImageInformation(AmazonEC2 ec2Client)
    {
        super(ec2Client);
    }

    @PostConstruct
    private void setup()
    {
        image = getLatestImage();
    }

    @Override
    public Image getImage()
    {
        return image;
    }

    @Override
    protected DescribeImagesRequest getRequest()
    {
        StringBuilder manifestLocation = new StringBuilder();
        
        manifestLocation.append("*pv-grub-");
        manifestLocation.append(bootPartition);
        manifestLocation.append("_*");

        return new DescribeImagesRequest().
                withOwners("amazon").
                withFilters(new Filter().withName("image-type").withValues("kernel"),
                            new Filter().withName("architecture").withValues(architecture),
                            new Filter().withName("manifest-location").withValues(manifestLocation.toString()));
    }
}

