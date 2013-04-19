
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeInstancesRequest;
import com.amazonaws.services.ec2.model.DescribeInstancesResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Instance;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SimpleBootstrapInstanceProvider implements Provider<Optional<Instance>>
{
    private static Logger log = LoggerFactory.getLogger(SimpleBootstrapInstanceProvider.class);

    private AmazonEC2 ec2Client;

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.instanceId")
    private Supplier<String> instanceId = Suppliers.ofInstance(null);

    @Inject
    public SimpleBootstrapInstanceProvider(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    @Override
    public Optional<Instance> get()
    {
        log.info("Get Bootstrap Instance");

        if (null == instanceId)
        {
            return Optional.absent();
        }

        DescribeInstancesResult result = ec2Client.describeInstances(new DescribeInstancesRequest().
                withFilters(new Filter().withName("instance-id").withValues(instanceId.get())));

        if (result.getReservations().isEmpty())
        {
            return Optional.absent();
        }

        if (result.getReservations().get(0).getInstances().isEmpty())
        {
            return Optional.absent();
        }

        return Optional.fromNullable(result.getReservations().get(0).getInstances().get(0));
    }
}

