/*
 *
 * AbstractParavirtualImageInformation.java
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

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractParavirtualImageInformation implements ImageInformation
{
    private static Logger log = LoggerFactory.getLogger(AbstractParavirtualImageInformation.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Image.architecture")
    private Supplier<String> architecture = Suppliers.ofInstance("x86_64");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Image.bootPartition")
    private Supplier<String> bootPartition = Suppliers.ofInstance("hd0");

    @Override
    public String getArchitecture()
    {
        return architecture.get();
    }

    @Override
    public String getVirtualizationType()
    {
        return "paravirtual";
    }

    @Override
    public String getBootPartition()
    {
        return bootPartition.get();
    }
}

