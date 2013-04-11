
package com.dowdandassociates.gentoo.bootstrap;

import java.util.HashMap;
import java.util.Map;
import java.util.SortedSet;
import java.util.TreeSet;
import java.util.regex.Pattern;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.DescribeImagesResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Image;

import com.google.inject.Inject;

public class AmazonLinuxPvX8664EbsAmi implements AmazonMachineImage
{
    private DescribeImagesRequest describeImagesRequest;
    private AmazonEC2 ec2Client;
    private Pattern rcPattern;

    @Inject
    public AmazonLinuxPvX8664EbsAmi(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;

        describeImagesRequest = new DescribeImagesRequest().
                withOwners("amazon").
                withFilters(new Filter().withName("image-type").withValues("machine"),
                            new Filter().withName("virtualization-type").withValues("paravirtual"),
                            new Filter().withName("architecture").withValues("x86_64"),
                            new Filter().withName("root-device-type").withValues("ebs"),
                            new Filter().withName("image-type").withValues("machine"),
                            new Filter().withName("manifest-location").withValues("amazon/amzn-ami-pv-*"));

        rcPattern = Pattern.compile(".*rc-.*");
    }

    @Override
    public String getImageId()
    {
        DescribeImagesResult result = ec2Client.describeImages(describeImagesRequest);

        Map<String, String> imageMap = new HashMap<String, String>();

        for (Image image : result.getImages())
        {
            String name = image.getName();
            if (!rcPattern.matcher(name).matches())
            {
                imageMap.put(image.getName(), image.getImageId());
            }
        }

        if (imageMap.isEmpty())
        {
            return null;
        }

        SortedSet<String> sortedKeySet = new TreeSet<String>();
        sortedKeySet.addAll(imageMap.keySet());
        String[] keys = sortedKeySet.toArray(new String[0]);
        return imageMap.get(keys[keys.length - 1]);
    }
}

