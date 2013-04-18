
package com.dowdandassociates.gentoo.bootstrap;

import java.util.HashMap;
import java.util.Map;
import java.util.SortedSet;
import java.util.TreeSet;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.DescribeImagesResult;
import com.amazonaws.services.ec2.model.Image;

import com.google.common.base.Optional;

import com.google.inject.Provider;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class LatestImageProvider implements Provider<Optional<Image>> 
{
    private static Logger log = LoggerFactory.getLogger(LatestImageProvider.class);

    private AmazonEC2 ec2Client;

    public LatestImageProvider(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    @Override
    public Optional<Image> get()
    {
        DescribeImagesResult result = ec2Client.describeImages(getRequest());

        Map<String, Image> imageMap = new HashMap<String, Image>();

        for (Image image : result.getImages())
        {
            imageMap.put(image.getImageLocation(), image);
        }

        if (imageMap.isEmpty())
        {
            return Optional.absent();
        }

        SortedSet<String> sortedKeySet = new TreeSet<String>();
        sortedKeySet.addAll(imageMap.keySet());
        String[] keys = sortedKeySet.toArray(new String[0]);
        return Optional.fromNullable(imageMap.get(keys[keys.length - 1]));
    }

    protected abstract DescribeImagesRequest getRequest();
}

