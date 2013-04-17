
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeInstancesRequest;
import com.amazonaws.services.ec2.model.DescribeInstancesResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Instance;

import com.google.inject.Inject;
import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

public class SimpleInstanceLookupProvider implements Provider<Instance>
{
    private AmazonEC2 ec2Client;

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Instance.instanceId")
    private String instanceId = null;

    @Inject
    public SimpleInstanceLookupProvider(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    public Instance get()
    {
        if (null == instanceId)
        {
            return null;
        }

        DescribeInstancesResult result = ec2Client.describeInstances(new DescribeInstancesRequest().
                withFilters(new Filter().withName("instance-id").withValues(instanceId)));

        if (result.getReservations().isEmpty())
        {
            return null;
        }

        if (result.getReservations().get(0).getInstances().isEmpty())
        {
            return null;
        }

        return result.getReservations().get(0).getInstances().get(0);
    }

}

