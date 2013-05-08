
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.DescribeImagesResult;
import com.amazonaws.services.ec2.model.Image;

import com.google.common.base.Optional;

import com.google.inject.Provider;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class SimpleImageProvider implements Provider<Optional<Image>>
{
    private static Logger log = LoggerFactory.getLogger(SimpleImageProvider.class);

    private AmazonEC2 ec2Client;

    public SimpleImageProvider(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    public Optional<Image> get()
    {
        String imageId = getImageId();

        if (null == imageId)
        {
            return Optional.absent();
        }

        DescribeImagesResult result = ec2Client.describeImages(new DescribeImagesRequest().
                withImageIds(imageId));

        if (result.getImages().isEmpty())
        {
            return Optional.absent();
        }

        return Optional.fromNullable(result.getImages().get(0));
    }

    protected abstract String getImageId();
}

