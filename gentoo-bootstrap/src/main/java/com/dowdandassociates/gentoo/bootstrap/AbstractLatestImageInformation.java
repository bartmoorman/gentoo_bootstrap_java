
package com.dowdandassociates.gentoo.bootstrap;

import java.util.HashMap;
import java.util.Map;
import java.util.SortedSet;
import java.util.TreeSet;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.DescribeImagesResult;
import com.amazonaws.services.ec2.model.Image;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractLatestImageInformation implements ImageInformation
{
    private static Logger log = LoggerFactory.getLogger(AbstractLatestImageInformation.class);

    private AmazonEC2 ec2Client;

    public AbstractLatestImageInformation(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    protected Image getLatestImage()
    {
        DescribeImagesResult result = ec2Client.describeImages(getRequest());

        Map<String, Image> imageMap = new HashMap<String, Image>();

        for (Image image : result.getImages())
        {
            imageMap.put(image.getImageLocation(), image);
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

    protected abstract DescribeImagesRequest getRequest();
}

