/*
 *
 * DefaultTemplateDataModelProvider.java
 *
 *-----------------------------------------------------------------------------
 * Copyright 2013 Dowd and Associates
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *-----------------------------------------------------------------------------
 *
 */

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

    @Configuration("com.dowdandassociates.gentoo.bootstrap.rootfstype")
    private Supplier<String> rootFsType = Suppliers.ofInstance("ext4");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.mountPoint")
    private Supplier<String> mountPoint = Suppliers.ofInstance("/mnt/gentoo");

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
        root.put("virtualizationType", imageInfo.getVirtualizationType());
        root.put("mirror", mirror.get());
        root.put("device", deviceInfo.getXvDevice());
        root.put("sDevice", deviceInfo.getSDevice());
        root.put("xvDevice", deviceInfo.getXvDevice());
        root.put("rootfstype", rootFsType.get());
        root.put("mountPoint", mountPoint.get());

        return root;
    }
}

