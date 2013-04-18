
package com.dowdandassociates.gentoo.core;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.AmazonEC2Client;

import com.google.common.base.Suppliers;
import com.google.common.base.Supplier;

import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

public class DefaultAmazonEC2Provider implements Provider<AmazonEC2>
{
    @Configuration("com.amazonaws.services.ec2.AmazonEC2.endpoint")
    private Supplier<String> endpoint = Suppliers.ofInstance("https://ec2.us-east-1.amazonaws.com");

    public DefaultAmazonEC2Provider()
    {
    }

    public AmazonEC2 get()
    {
        AmazonEC2 ec2Client = new AmazonEC2Client();
        ec2Client.setEndpoint(endpoint.get());
        return ec2Client;
    }
}

