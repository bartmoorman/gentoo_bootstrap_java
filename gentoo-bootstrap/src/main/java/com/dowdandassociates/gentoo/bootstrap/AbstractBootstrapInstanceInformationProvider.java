
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.AttachVolumeRequest;
import com.amazonaws.services.ec2.model.AttachVolumeResult;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;

import com.google.inject.Provider;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractBootstrapInstanceInformationProvider implements Provider<BootstrapInstanceInformation>
{
    private static Logger log = LoggerFactory.getLogger(AbstractBootstrapInstanceInformationProvider.class);

    private AmazonEC2 ec2Client;
    private BlockDeviceInformation blockDeviceInformation;
    private Optional<Image> bootstrapImage;
    private KeyPairInformation keyPairInformation;
    private SecurityGroupInformation securityGroupInformation;

    public AbstractBootstrapInstanceInformationProvider(
            AmazonEC2 ec2Client,
            Optional<Image> bootstrapImage,
            KeyPairInformation keyPairInformation,
            SecurityGroupInformation securityGroupInformation,
            BlockDeviceInformation blockDeviceInformation)
    {
        this.ec2Client = ec2Client;
        this.blockDeviceInformation = blockDeviceInformation;
        this.bootstrapImage = bootstrapImage;
        this.keyPairInformation = keyPairInformation;
        this.securityGroupInformation = securityGroupInformation;
    }

    public BootstrapInstanceInformation get()
    {
        log.info("get BootstrapInstanceInformation");
        Optional<Instance> instance = generateInstance();
        Optional<Volume> volume = generateVolume();
        attachVolume(instance, volume);

        return new BootstrapInstanceInformation().
                withInstance(instance).
                withVolume(volume);
    }

    protected AmazonEC2 getEc2Client()
    {
        return ec2Client;
    }

    protected BlockDeviceInformation getBlockDeviceInformation()
    {
        return blockDeviceInformation;
    }

    protected Optional<Image> getBootstrapImage()
    {
        return bootstrapImage;
    }

    protected KeyPairInformation getKeyPairInformation()
    {
        return keyPairInformation;
    }

    protected SecurityGroupInformation getSecurityGroupInformation()
    {
        return securityGroupInformation;
    }

    /**
     * Start an instance.
     */
    protected abstract Optional<Instance> generateInstance();

    /**
     * Create the bootstrap volume, if applicable.
     */
    protected abstract Optional<Volume> generateVolume();

    protected void attachVolume(Optional<Instance> instance, Optional<Volume> volume)
    {
        if (instance.isPresent() && volume.isPresent())
        {
            AttachVolumeResult result = ec2Client.attachVolume(new AttachVolumeRequest().
                    withInstanceId(instance.get().getInstanceId()).
                    withVolumeId(volume.get().getVolumeId()).
                    withDevice(blockDeviceInformation.getSDevice()));
        }
    }
}

