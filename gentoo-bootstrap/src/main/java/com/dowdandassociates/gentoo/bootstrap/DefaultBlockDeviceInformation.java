
package com.dowdandassociates.gentoo.bootstrap;

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.netflix.governator.annotations.Configuration;
import com.netflix.governator.guice.lazy.FineGrainedLazySingleton;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@FineGrainedLazySingleton
public class DefaultBlockDeviceInformation implements BlockDeviceInformation
{
    private static Logger log = LoggerFactory.getLogger(DefaultBlockDeviceInformation.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.device")
    private Supplier<String> device = Suppliers.ofInstance("f");

    @Override
    public String getSDevice()
    {
        return "/dev/sd" + device.get();
    }

    @Override
    public String getXvDevice()
    {
        return "/dev/xvd" + device.get();
    }
}

