
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeVolumesRequest;
import com.amazonaws.services.ec2.model.DescribeVolumesResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SimpleBootstrapVolumeProvider implements Provider<Optional<Volume>>
{
    private static Logger log = LoggerFactory.getLogger(SimpleBootstrapVolumeProvider.class);

    private AmazonEC2 ec2Client;

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapVolume.volumeId")
    private Supplier<String> volumeId = Suppliers.ofInstance(null);

    @Inject
    public SimpleBootstrapVolumeProvider(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    @Override
    public Optional<Volume> get()
    {
        log.info("Get Bootstrap Volume");

        if (null == volumeId)
        {
            return Optional.absent();
        }

        DescribeVolumesResult result = ec2Client.describeVolumes(new DescribeVolumesRequest().
                withFilters(new Filter().withName("volume-id").withValues(volumeId.get())));

        if (result.getVolumes().isEmpty())
        {
            return Optional.absent();
        }

        return Optional.fromNullable(result.getVolumes().get(0));
    }
}

