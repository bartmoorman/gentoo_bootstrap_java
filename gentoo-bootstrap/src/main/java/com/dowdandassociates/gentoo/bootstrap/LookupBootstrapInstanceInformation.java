
package com.dowdandassociates.gentoo.bootstrap;

import javax.annotation.PostConstruct;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeInstancesRequest;
import com.amazonaws.services.ec2.model.DescribeInstancesResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Instance;

import com.google.inject.Inject;
import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;
import com.netflix.governator.guice.lazy.FineGrainedLazySingleton;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@FineGrainedLazySingleton
public class LookupBootstrapInstanceInformation implements BootstrapInstanceInformation
{
    private static Logger log = LoggerFactory.getLogger(LookupBootstrapInstanceInformation.class);

    private AmazonEC2 ec2Client;

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapInstanceInformation.instanceId")
    private String instanceId = null;

    private Instance instance;

    @Inject
    public LookupBootstrapInstanceInformation (AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    @PostConstruct
    private void setup()
    {
        if (null == instanceId)
        {
            instance = null;
            return;
        }

        DescribeInstancesResult result = ec2Client.describeInstances(new DescribeInstancesRequest().
                withFilters(new Filter().withName("instance-id").withValues(instanceId)));

        if (result.getReservations().isEmpty())
        {
            instance = null;
            return;
        }

        if (result.getReservations().get(0).getInstances().isEmpty())
        {
            instance = null;
            return;
        }

        instance = result.getReservations().get(0).getInstances().get(0);
    }

    @Override
    public Instance getInstance()
    {
        return instance;
    }
}

