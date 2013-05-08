
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;

import com.google.common.base.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractOnDemandBootstrapInstanceInformationProvider extends AbstractBootstrapInstanceInformationProvider
{
    private static Logger log = LoggerFactory.getLogger(AbstractOnDemandBootstrapInstanceInformationProvider.class);

    private Optional<Image> bootstrapImage;
    private KeyPairInformation keyPairInformation;
    private SecurityGroupInformation securityGroupInformation;

    public AbstractOnDemandBootstrapInstanceInformationProvider(
            AmazonEC2 ec2Client,
            Optional<Image> bootstrapImage,
            KeyPairInformation keyPairInformation,
            SecurityGroupInformation securityGroupInformation,
            BlockDeviceInformation blockDeviceInformation)
    {
        super(ec2Client, bootstrapImage, keyPairInformation, securityGroupInformation, blockDeviceInformation);
    }

    @Override
    protected Optional<Instance> generateInstance()
    {
        if (!bootstrapImage.isPresent())
        {
            return Optional.absent();
        }

        // TODO: replace with run instances
        return Optional.absent();
    }
}

