
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.GroupIdentifier;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;

//import com.google.inject.AbstractModule;
import com.google.inject.TypeLiteral;
import com.google.inject.name.Names;

import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.UserInfo;

import com.netflix.governator.configuration.ArchaiusConfigurationProvider;
import com.netflix.governator.guice.BootstrapBinder;
import com.netflix.governator.guice.BootstrapModule;

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
public class GentooBootstrapModule implements BootstrapModule 
{
    @Override
    public void configure(BootstrapBinder binder)
    {
        binder.bindConfigurationProvider().to(ArchaiusConfigurationProvider.class);
        binder.bind(AmazonEC2.class).toProvider(DefaultAmazonEC2Provider.class);
        binder.bind(KeyPairInformation.class).to(DefaultKeyPairInformation.class);
        binder.bind(SecurityGroupInformation.class).to(DefaultSecurityGroupInformation.class);
        binder.bind(new TypeLiteral<Optional<Image>>() {}).annotatedWith(Names.named("Bootstrap Image")).toProvider(DefaultBootstrapImageProvider.class);
        binder.bind(new TypeLiteral<Optional<Image>>() {}).annotatedWith(Names.named("Kernel Image")).toProvider(DefaultKernelImageProvider.class);
        binder.bind(new TypeLiteral<Optional<Instance>>() {}).annotatedWith(Names.named("Bootstrap Instance")).toProvider(SimpleBootstrapInstanceProvider.class);
        binder.bind(new TypeLiteral<Optional<Volume>>() {}).annotatedWith(Names.named("Bootstrap Volume")).toProvider(SimpleBootstrapVolumeProvider.class);
        binder.bind(UserInfo.class).to(DefaultUserInfo.class);
        binder.bind(new TypeLiteral<Optional<JSch>>() {}).toProvider(JSchProvider.class);
        binder.bind(BootstrapInstanceInformation.class).toProvider(DefaultBootstrapInstanceInformationProvider.class);
        binder.bind(BootstrapSessionInformation.class).toProvider(DefaultBootstrapSessionInformationProvider.class);
    }
}

