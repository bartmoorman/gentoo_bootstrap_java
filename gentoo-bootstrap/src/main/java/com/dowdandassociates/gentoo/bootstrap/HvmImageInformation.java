/*
 *
 * HvmImageInformation.java
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

