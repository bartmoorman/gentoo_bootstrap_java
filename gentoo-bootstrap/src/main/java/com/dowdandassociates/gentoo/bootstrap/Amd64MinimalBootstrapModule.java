
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;

import com.google.inject.AbstractModule;
import com.google.inject.name.Names;

import com.dowdandassociates.gentoo.core.DefaultAmazonEC2Provider;

public class Amd64MinimalBootstrapModule extends AbstractModule
{
    @Override
    protected void configure()
    {
        bind(AmazonEC2.class).toProvider(DefaultAmazonEC2Provider.class);
        bind(KeyPair.class).to(ArchaiusKeyPair.class);
        bind(SecurityGroup.class).to(ArchaiusSecurityGroupCidr.class);
        bind(DescribeImagesRequest.class).annotatedWith(Names.named("Machine Image")).toProvider(AmazonLinuxPvX8664EbsAmiProvider.class);
        bind(DescribeImagesRequest.class).annotatedWith(Names.named("Kernel Image")).toProvider(PvGrubHd0X8664AkiProvider.class);
        bind(AmazonMachineImage.class).annotatedWith(Names.named("Bootstrap Image")).to(LastMachineImage.class);
        bind(AmazonKernelImage.class).to(LastKernelImage.class);
    }
}

