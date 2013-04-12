
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;

import com.google.inject.Inject;
import com.google.inject.name.Named;

public class LastMachineImage extends LastImage implements AmazonMachineImage
{
    private DescribeImagesRequest request;
    private AmazonEC2 ec2Client;

    @Inject
    public LastMachineImage(AmazonEC2 ec2Client, @Named("Machine Image") DescribeImagesRequest request)
    {
        this.ec2Client = ec2Client;
        this.request = request;
    }

    @Override
    protected DescribeImagesRequest getRequest()
    {
        return request;
    }

    @Override
    protected AmazonEC2 getEC2Client()
    {
        return ec2Client;
    }
}

