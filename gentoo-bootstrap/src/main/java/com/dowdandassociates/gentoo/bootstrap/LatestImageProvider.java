
package com.dowdandassociates.gentoo.bootstrap;

import java.util.HashMap;
import java.util.Map;
import java.util.SortedSet;
import java.util.TreeSet;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.DescribeImagesResult;
import com.amazonaws.services.ec2.model.Image;

import com.google.inject.Provider;

public abstract class LatestImageProvider implements Provider<Image>
{
    private AmazonEC2 ec2Client;
    private DescribeImagesRequest request;

    public LatestImageProvider(AmazonEC2 ec2Client, DescribeImagesRequest request)
    {
        this.ec2Client = ec2Client;
        this.request = request;
    }

    @Override
    public Image get()
    {
        DescribeImagesResult result = ec2Client.describeImages(request);

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
}

