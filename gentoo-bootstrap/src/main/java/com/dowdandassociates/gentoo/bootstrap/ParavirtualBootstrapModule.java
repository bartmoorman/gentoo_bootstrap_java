/*
 *
 * ParavirtualBootstrapModule.java
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

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.GroupIdentifier;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Snapshot;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;

//import com.google.inject.AbstractModule;
import com.google.inject.TypeLiteral;
import com.google.inject.name.Names;

import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.UserInfo;

import com.netflix.governator.configuration.ArchaiusConfigurationProvider;
import com.netflix.governator.guice.BootstrapBinder;
import com.netflix.governator.guice.BootstrapModule;

import freemarker.template.Template;

/*
public class Amd64MinimalBootstrapModule extends AbstractModule
{
    @Override
    protected void configure()
    {
        bind(AmazonEC2.class).toProvider(DefaultAmazonEC2Provider.class);
        bind(KeyPairInformation.class).to(ArchaiusKeyPairInformation.class);
        bind(SecurityGroupInformation.class).to(ArchaiusSecurityGroupInformation.class);
        bind(Image.class).annotatedWith(Names.named("Bootstrap Image")).toProvider(AmazonLinuxPvX8664EbsAmiProvider.class);
        bind(Image.class).annotatedWith(Names.named("Kernel Image")).toProvider(PvGrubHd0X8664AkiProvider.class);
    }
}
*/
public class ParavirtualBootstrapModule extends GentooBootstrapModule 
{
    @Override
    public void configure(BootstrapBinder binder)
    {
        super.configure(binder);
        binder.bind(ImageInformation.class).to(ParavirtualEbsImageInformation.class);
    }
}

