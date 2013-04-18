
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
public class LatestBootstrapImageInformation
        extends AbstractLatestImageInformation
        implements BootstrapImageInformation
{
    private static Logger log = LoggerFactory.getLogger(LatestBootstrapImageInformation.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapImageInformation.virtualizationType")
    private String virtualizationType = "paravirtual";

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapImageInformation.architecture")
    private String architecture = "x86_64";

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapImageInformation.rootDeviceType")
    private String rootDeviceType = "ebs";

    private Image image;

    @Inject
    public LatestBootstrapImageInformation(AmazonEC2 ec2Client)
    {
        super(ec2Client);
    }

    @PostConstruct
    private void setup()
    {
        if ("hvm".equals(virtualizationType))
        {
            architecture = "x86_64";
            rootDeviceType = "ebs";
        }

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
        
        manifestLocation.append("*/amzn-ami-");
        if ("hvm".equals(virtualizationType))
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
                            new Filter().withName("virtualization-type").withValues(virtualizationType),
                            new Filter().withName("architecture").withValues(architecture),
                            new Filter().withName("root-device-type").withValues(rootDeviceType),
                            new Filter().withName("manifest-location").withValues(manifestLocation.toString()));

    }
}

