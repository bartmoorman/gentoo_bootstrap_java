
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;

import com.google.inject.Inject;
import com.google.inject.name.Named;

public class LastKernelImage extends LastImage implements AmazonKernelImage
{
    private DescribeImagesRequest request;
    private AmazonEC2 ec2Client;

    @Inject
    public LastKernelImage(AmazonEC2 ec2Client, @Named("Kernel Image") DescribeImagesRequest request)
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

