
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
public class GentooBootstrapModule implements BootstrapModule 
{
    @Override
    public void configure(BootstrapBinder binder)
    {
        binder.bindConfigurationProvider().to(ArchaiusConfigurationProvider.class);
        binder.bind(AmazonEC2.class).toProvider(DefaultAmazonEC2Provider.class);
        binder.bind(KeyPairInformation.class).to(DefaultKeyPairInformation.class);
        binder.bind(SecurityGroupInformation.class).to(DefaultSecurityGroupInformation.class);
//        binder.bind(new TypeLiteral<Optional<Image>>() {}).annotatedWith(Names.named("Bootstrap Image")).toProvider(SimpleBootstrapImageProvider.class);
        binder.bind(new TypeLiteral<Optional<Image>>() {}).annotatedWith(Names.named("Bootstrap Image")).toProvider(DefaultBootstrapImageProvider.class);
//        binder.bind(new TypeLiteral<Optional<Image>>() {}).annotatedWith(Names.named("Kernel Image")).toProvider(SimpleKernelImageProvider.class);
        binder.bind(new TypeLiteral<Optional<Image>>() {}).annotatedWith(Names.named("Kernel Image")).toProvider(DefaultKernelImageProvider.class);
        binder.bind(UserInfo.class).to(DefaultUserInfo.class);
        binder.bind(new TypeLiteral<Optional<JSch>>() {}).toProvider(JSchProvider.class);
        binder.bind(BootstrapInstanceInformation.class).toProvider(SimpleBootstrapInstanceInformationProvider.class);
//        binder.bind(BootstrapInstanceInformation.class).toProvider(SnapshotOnDemandBootstrapInstanceInformationProvider.class);
//        binder.bind(BootstrapInstanceInformation.class).toProvider(EbsOnDemandBootstrapInstanceInformationProvider.class);
        binder.bind(BootstrapSessionInformation.class).toProvider(DefaultBootstrapSessionInformationProvider.class);
        binder.bind(new TypeLiteral<Optional<Template>>() {}).toProvider(DefaultTemplateProvider.class);
        binder.bind(ImageInformation.class).to(ParavirtualEbsImageInformation.class);
        binder.bind(Object.class).annotatedWith(Names.named("Template Data Model")).toProvider(DefaultTemplateDataModelProvider.class);
        binder.bind(new TypeLiteral<Supplier<String>>() {}).annotatedWith(Names.named("Script Name")).toProvider(DefaultScriptNameProvider.class);
        binder.bind(ProcessedTemplate.class).toProvider(DefaultProcessedTemplateProvider.class);
        binder.bind(BootstrapCommandInformation.class).toProvider(DefaultBootstrapCommandInformationProvider.class);
        binder.bind(BootstrapResultInformation.class).toProvider(DefaultBootstrapResultInformationProvider.class);
        binder.bind(BlockDeviceInformation.class).to(DefaultBlockDeviceInformation.class);
        binder.bind(new TypeLiteral<Optional<Snapshot>>() {}).annotatedWith(Names.named("Test Snapshot")).toProvider(DefaultTestSnapshotProvider.class);
        binder.bind(new TypeLiteral<Optional<Image>>() {}).annotatedWith(Names.named("Test Image")).toProvider(DefaultTestImageProvider.class);
        binder.bind(TestInstanceInformation.class).toProvider(EbsOnDemandTestInstanceInformationProvider.class);
        binder.bind(TestSessionInformation.class).toProvider(DefaultTestSessionInformationProvider.class);
        binder.bind(TestResultInformation.class).toProvider(DefaultTestResultInformationProvider.class);
        binder.bind(new TypeLiteral<Optional<Image>>() {}).annotatedWith(Names.named("Gentoo Image")).toProvider(DefaultGentooImageProvider.class);
    }
}

