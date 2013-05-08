
package com.dowdandassociates.gentoo.bootstrap;

import java.util.HashMap;
import java.util.Map;

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;
import com.google.inject.name.Named;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultTemplateDataModelProvider implements Provider<Object>
{
    private static Logger log = LoggerFactory.getLogger(DefaultTemplateDataModelProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.mirror")
    private Supplier<String> mirror = Suppliers.ofInstance("http://gentoo.mirrors.pair.com/");

    private ImageInformation imageInfo;
    private BlockDeviceInformation deviceInfo;

    @Inject
    private void setImageInfo(ImageInformation imageInfo)
    {
        this.imageInfo = imageInfo;
    }

    @Inject
    private void setDeviceInfo(BlockDeviceInformation deviceInfo)
    {
        this.deviceInfo = deviceInfo;
    }

    public Object get()
    {
        Map root = new HashMap();

        root.put("architecture", imageInfo.getArchitecture());
        root.put("mirror", mirror.get());
        root.put("device", deviceInfo.getXvDevice());
        root.put("sDevice", deviceInfo.getSDevice());
        root.put("xvDevice", deviceInfo.getXvDevice());

        return root;
    }
}

