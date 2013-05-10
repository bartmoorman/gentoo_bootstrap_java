
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeInstancesRequest;
import com.amazonaws.services.ec2.model.DescribeInstancesResult;
import com.amazonaws.services.ec2.model.DescribeInstanceStatusRequest;
import com.amazonaws.services.ec2.model.DescribeInstanceStatusResult;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.InstanceStatus;
import com.amazonaws.services.ec2.model.Placement;
import com.amazonaws.services.ec2.model.RunInstancesRequest;
import com.amazonaws.services.ec2.model.RunInstancesResult;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.name.Named;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class EbsOnDemandTestInstanceInformationProvider extends AbstractTestInstanceInformationProvider
{
    private static Logger log = LoggerFactory.getLogger(EbsOnDemandTestInstanceInformationProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestInstance.checkInstanceSleep")
    private Supplier<Long> sleep = Suppliers.ofInstance(10000L);

    @Inject
    public EbsOnDemandTestInstanceInformationProvider(
            AmazonEC2 ec2Client,
            @Named("Test Image") Optional<Image> testImage,
            KeyPairInformation keyPairInformation,
            SecurityGroupInformation securityGroupInformation)
    {
        super(ec2Client, testImage, keyPairInformation, securityGroupInformation);
    }

    @Override
    protected Optional<Instance> generateInstance()
    {
        return InstanceUtils.onDemandInstance(
                getEc2Client(),
                getTestImage(),
                1,
                1,
                getSecurityGroupInformation(),
                getKeyPairInformation(),
                getInstanceType(),
                getAvailabilityZone(),
                sleep.get());
    }
}

