
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;

import com.google.inject.Inject;
import com.google.inject.name.Named;

public class LastKernelImageProvider extends ImageProvider
{
    private DescribeImagesRequest request;
    private AmazonEC2 ec2Client;

    @Inject
    public LastKernelImageProvider(AmazonEC2 ec2Client, @Named("Kernel Image") DescribeImagesRequest request)
    {
        super(ec2Client, request);
    }
}

