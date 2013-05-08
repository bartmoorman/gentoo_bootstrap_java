
package com.dowdandassociates.gentoo.bootstrap;

import com.netflix.governator.guice.lazy.FineGrainedLazySingleton;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@FineGrainedLazySingleton
public abstract class HvmImageInformation implements ImageInformation
{
    private static Logger log = LoggerFactory.getLogger(HvmImageInformation.class);

    @Override
    public String getArchitecture()
    {
        return "x86_64";
    }

    @Override
    public String getVirtualizationType()
    {
        return "hvm";
    }

    @Override
    public String getBootPartition()
    {
        return null;
    }

    @Override
    public String getRootDeviceType()
    {
        return "ebs";
    }
}

