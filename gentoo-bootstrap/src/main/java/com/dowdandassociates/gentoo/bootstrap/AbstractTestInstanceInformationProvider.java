
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.AttachVolumeRequest;
import com.amazonaws.services.ec2.model.AttachVolumeResult;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractTestInstanceInformationProvider implements Provider<TestInstanceInformation>
{
    private static Logger log = LoggerFactory.getLogger(AbstractTestInstanceInformationProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestInstance.instanceType")
    private Supplier<String> instanceType = Suppliers.ofInstance(null);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestInstance.availabilityZone")
    private Supplier<String> availabilityZone = Suppliers.ofInstance(null);

    private AmazonEC2 ec2Client;
    private Optional<Image> testImage;
    private KeyPairInformation keyPairInformation;
    private SecurityGroupInformation securityGroupInformation;

    public AbstractTestInstanceInformationProvider(
            AmazonEC2 ec2Client,
            Optional<Image> testImage,
            KeyPairInformation keyPairInformation,
            SecurityGroupInformation securityGroupInformation)
    {
        this.ec2Client = ec2Client;
        this.testImage = testImage;
        this.keyPairInformation = keyPairInformation;
        this.securityGroupInformation = securityGroupInformation;
    }

    public TestInstanceInformation get()
    {
        log.info("get TestInstanceInformation");
        Optional<Instance> instance = generateInstance();

        return new TestInstanceInformation().
                withInstance(instance).
                withImage(testImage);
    }

    protected AmazonEC2 getEc2Client()
    {
        return ec2Client;
    }

    protected Optional<Image> getTestImage()
    {
        return testImage;
    }

    protected KeyPairInformation getKeyPairInformation()
    {
        return keyPairInformation;
    }

    protected SecurityGroupInformation getSecurityGroupInformation()
    {
        return securityGroupInformation;
    }

    protected Optional<String> getInstanceType()
    {
        return Optional.fromNullable(instanceType.get());
    }

    protected Optional<String> getAvailabilityZone()
    {
        return Optional.fromNullable(availabilityZone.get());
    }

    /**
     * Start an instance.
     */
    protected abstract Optional<Instance> generateInstance();
}

