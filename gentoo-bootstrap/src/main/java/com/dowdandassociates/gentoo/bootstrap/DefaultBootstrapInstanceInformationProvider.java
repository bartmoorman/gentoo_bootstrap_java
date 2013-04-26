
package com.dowdandassociates.gentoo.bootstrap;

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

public class DefaultBootstrapInstanceInformationProvider implements Provider<BootstrapInstanceInformation>
{
    private static Logger log = LoggerFactory.getLogger(DefaultBootstrapInstanceInformationProvider.class);

    private Optional<Instance> instance;
    private Optional<Volume> volume;

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.device")
    private Supplier<String> device = Suppliers.ofInstance("/dev/xvdf");

    @Inject
    public DefaultBootstrapInstanceInformationProvider(
            @Named("Bootstrap Instance") Optional<Instance> instance,
            @Named("Bootstrap Volume") Optional<Volume> volume)
    {
        this.instance = instance;
        this.volume = volume;
    }

    public BootstrapInstanceInformation get()
    {
        // TODO: attach volume

        return new BootstrapInstanceInformation().
                withInstance(instance).
                withVolume(volume).
                withDevice(Optional.fromNullable(device.get()));
    }

}

