
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.GroupIdentifier;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;

//import com.google.inject.AbstractModule;
import com.google.inject.name.Names;

import com.netflix.governator.configuration.ArchaiusConfigurationProvider;
import com.netflix.governator.guice.BootstrapBinder;
import com.netflix.governator.guice.BootstrapModule;

import com.dowdandassociates.gentoo.core.DefaultAmazonEC2Provider;
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
public class Amd64MinimalBootstrapModule implements BootstrapModule 
{
    @Override
    public void configure(BootstrapBinder binder)
    {
        binder.bindConfigurationProvider().to(ArchaiusConfigurationProvider.class);
        binder.bind(AmazonEC2.class).toProvider(DefaultAmazonEC2Provider.class);
        binder.bind(KeyPairInformation.class).to(DefaultKeyPairInformation.class);
        binder.bind(SecurityGroupInformation.class).to(DefaultSecurityGroupInformation.class);
        binder.bind(Image.class).annotatedWith(Names.named("Bootstrap Image")).toProvider(AmazonLinuxPvX8664EbsAmiProvider.class);
        binder.bind(Image.class).annotatedWith(Names.named("Kernel Image")).toProvider(PvGrubHd0X8664AkiProvider.class);
        binder.bind(Instance.class).annotatedWith(Names.named("Bootstrap Instance")).toProvider(SimpleInstanceLookupProvider.class);
    }
}

