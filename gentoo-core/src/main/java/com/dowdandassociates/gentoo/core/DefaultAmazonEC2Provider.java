
package com.dowdandassociates.gentoo.core;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.AmazonEC2Client;

import com.google.inject.Provider;

import com.netflix.config.DynamicPropertyFactory;
import com.netflix.config.DynamicStringProperty;

public class DefaultAmazonEC2Provider implements Provider<AmazonEC2>
{
    private static final String ENDPOINT_PROPERTY = "com.amazonaws.services.ec2.AmazonEC2.endpoint";
    private static final String DEFAULT_ENDPOINT = "https://ec2.us-east-1.amazonaws.com";

    private DynamicStringProperty endpoint;

    public DefaultAmazonEC2Provider()
    {
        endpoint = DynamicPropertyFactory.getInstance().getStringProperty(ENDPOINT_PROPERTY, DEFAULT_ENDPOINT);
    }

    public AmazonEC2 get()
    {
        AmazonEC2 ec2Client = new AmazonEC2Client();
        ec2Client.setEndpoint(endpoint.get());
        return ec2Client;
    }
}

