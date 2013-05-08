
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeInstancesRequest;
import com.amazonaws.services.ec2.model.DescribeInstancesResult;
import com.amazonaws.services.ec2.model.DescribeVolumesRequest;
import com.amazonaws.services.ec2.model.DescribeVolumesResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;
import com.google.inject.name.Named;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SimpleBootstrapInstanceInformationProvider extends AbstractBootstrapInstanceInformationProvider
{
    private static Logger log = LoggerFactory.getLogger(SimpleBootstrapInstanceInformationProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.instanceId")
    private Supplier<String> instanceId = Suppliers.ofInstance(null);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapVolume.volumeId")
    private Supplier<String> volumeId = Suppliers.ofInstance(null);

    @Inject
    public SimpleBootstrapInstanceInformationProvider(AmazonEC2 ec2Client, BlockDeviceInformation blockDeviceInformation)
    {
        super(ec2Client, blockDeviceInformation);
    }

    @Override
    protected Optional<Instance> generateInstance()
    {
        log.info("Get Bootstrap Instance");

        if (null == instanceId.get())
        {
            return Optional.absent();
        }

        DescribeInstancesResult result = getEc2Client().describeInstances(new DescribeInstancesRequest().
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

    @Override
    protected Optional<Volume> generateVolume()
    {
        log.info("Get Bootstrap Volume");

        if (null == volumeId.get())
        {
            return Optional.absent();
        }

        DescribeVolumesResult result = getEc2Client().describeVolumes(new DescribeVolumesRequest().
                withFilters(new Filter().withName("volume-id").withValues(volumeId.get())));

        if (result.getVolumes().isEmpty())
        {
            return Optional.absent();
        }

        return Optional.fromNullable(result.getVolumes().get(0));
    }

    @Override
    protected void attachVolume(Optional<Instance> instance, Optional<Volume> volume)
    {
        // Do nothing. Manually attach volume.
    }
}

