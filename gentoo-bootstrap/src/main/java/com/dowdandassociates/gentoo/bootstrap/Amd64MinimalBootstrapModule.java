
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;

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
        bind(AmazonMachineImage.class).annotatedWith(Names.named("Bootstrap Image")).to(AmazonLinuxPvX8664EbsAmi.class);
    }
}

