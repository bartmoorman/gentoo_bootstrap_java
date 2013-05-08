
package com.dowdandassociates.gentoo.bootstrap;

import com.netflix.governator.guice.lazy.FineGrainedLazySingleton;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@FineGrainedLazySingleton
public class ParavirtualEbsImageInformation extends AbstractParavirtualImageInformation
{
    private static Logger log = LoggerFactory.getLogger(ParavirtualEbsImageInformation.class);

    @Override
    public String getRootDeviceType()
    {
        return "ebs";
    }
}

