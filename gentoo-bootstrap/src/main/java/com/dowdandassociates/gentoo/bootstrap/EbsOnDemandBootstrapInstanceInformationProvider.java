
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

public class EbsOnDemandBootstrapInstanceInformationProvider extends AbstractOnDemandBootstrapInstanceInformationProvider
{
    private static Logger log = LoggerFactory.getLogger(EbsOnDemandBootstrapInstanceInformationProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.volumeSize")
    private Supplier<Integer> volumeSize = Suppliers.ofInstance(10);

    @Inject
    public EbsOnDemandBootstrapInstanceInformationProvider(
            AmazonEC2 ec2Client,
            @Named("Bootstrap Image") Optional<Image> bootstrapImage,
            KeyPairInformation keyPairInformation,
            SecurityGroupInformation securityGroupInformation,
            BlockDeviceInformation blockDeviceInformation)
    {
        super(ec2Client, bootstrapImage, keyPairInformation, securityGroupInformation, blockDeviceInformation);
    }

    @Override
    protected Optional<Volume> generateVolume()
    {
        if (!getBootstrapImage().isPresent())
        {
            return Optional.absent();
        }

        // TODO: replace with create volume
        return Optional.absent();
    }
}

