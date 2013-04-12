
package com.dowdandassociates.gentoo.bootstrap;

import java.util.HashMap;
import java.util.Map;
import java.util.SortedSet;
import java.util.TreeSet;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.DescribeImagesResult;
import com.amazonaws.services.ec2.model.Image;

public abstract class LastImage implements AmazonImage
{
    @Override
    public String getImageId()
    {
        DescribeImagesResult result = getEC2Client().describeImages(getRequest());

        Map<String, String> imageMap = new HashMap<String, String>();

        for (Image image : result.getImages())
        {
            imageMap.put(image.getImageLocation(), image.getImageId());
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

    protected abstract AmazonEC2 getEC2Client();
    protected abstract DescribeImagesRequest getRequest();
}

