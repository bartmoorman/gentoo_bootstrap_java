
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;

import com.google.inject.Inject;
import com.google.inject.Provider;
import com.google.inject.name.Named;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractBootstrapInstanceInformationProvider implements Provider<BootstrapInstanceInformation>
{
    private static Logger log = LoggerFactory.getLogger(AbstractBootstrapInstanceInformationProvider.class);

    private AmazonEC2 ec2Client;
    private BlockDeviceInformation blockDeviceInformation;

    public AbstractBootstrapInstanceInformationProvider(
            AmazonEC2 ec2Client,
            BlockDeviceInformation blockDeviceInformation)
    {
        this.ec2Client = ec2Client;
        this.blockDeviceInformation = blockDeviceInformation;
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
            // TODO: attach volume
        }
    }
}

