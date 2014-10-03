/*
 *
 * DefaultTestImageProvider.java
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
import com.amazonaws.services.ec2.model.BlockDeviceMapping;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.DescribeImagesResult;
import com.amazonaws.services.ec2.model.EbsBlockDevice;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.RegisterImageRequest;
import com.amazonaws.services.ec2.model.RegisterImageResult;
import com.amazonaws.services.ec2.model.Snapshot;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;
import com.google.inject.name.Named;

import com.netflix.governator.annotations.Configuration;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.time.DateFormatUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultTestImageProvider implements Provider<Optional<Image>>
{
    private static Logger log = LoggerFactory.getLogger(DefaultTestImageProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestImage.prefix")
    private Supplier<String> prefix = Suppliers.ofInstance("Gentoo_EBS");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestImage.dateFormat")
    private Supplier<String> dateFormat = Suppliers.ofInstance("-yyyy-MM-dd-HH-mm-ss");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestImage.description")
    private Supplier<String> description = Suppliers.ofInstance("Gentoo EBS");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestImage.rootDeviceName")
    private Supplier<String> rootDeviceName = Suppliers.ofInstance("/dev/sda1");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestImage.checkImageSleep")
    private Supplier<Long> sleep = Suppliers.ofInstance(10000L);

    private AmazonEC2 ec2Client;
    private Optional<Snapshot> testSnapshot;
    private ImageInformation imageInformation;
    private Optional<Image> kernelImage;

    @Inject
    public DefaultTestImageProvider(AmazonEC2 ec2Client, @Named("Test Snapshot") Optional<Snapshot> testSnapshot, ImageInformation imageInformation, @Named("Kernel Image") Optional<Image> kernelImage)
    {
        this.ec2Client = ec2Client;
        this.testSnapshot = testSnapshot;
        this.imageInformation = imageInformation;
        this.kernelImage = kernelImage;
    }

    public Optional<Image> get()
    {
        if (!testSnapshot.isPresent())
        {
            log.info("test snapshot not present");
            return Optional.absent();
        }

        StringBuilder name = new StringBuilder();
        name.append(prefix.get());

        if (StringUtils.isNotBlank(dateFormat.get()))
        {
            name.append(DateFormatUtils.formatUTC(System.currentTimeMillis(), dateFormat.get()));
        }

        String architecture = imageInformation.getArchitecture();
        String virtualizationType = imageInformation.getVirtualizationType();

        RegisterImageRequest registerImageRequest = new RegisterImageRequest().
                withArchitecture(architecture).
                withVirtualizationType(virtualizationType).
                withDescription(description.get()).
                withName(name.toString()).
                withRootDeviceName(rootDeviceName.get());

        if ("paravirtual".equals(virtualizationType))
        {
            if (!kernelImage.isPresent())
            {
                log.info("kernel image not present");
                return Optional.absent();
            }

            registerImageRequest = registerImageRequest.
                    withKernelId(kernelImage.get().getImageId());
        }

        if ("i386".equals(architecture))
        {
            registerImageRequest = registerImageRequest.
                    withBlockDeviceMappings(
                            new BlockDeviceMapping().
                                    withDeviceName(rootDeviceName.get()).
                                    withEbs(new EbsBlockDevice().
                                            withSnapshotId(testSnapshot.get().getSnapshotId())),
                            new BlockDeviceMapping().
                                    withDeviceName("/dev/sda2").
                                    withVirtualName("ephemeral0"),
                            new BlockDeviceMapping().
                                    withDeviceName("/dev/sda3").
                                    withVirtualName("ephemeral1"));
        }
        else
        {
            registerImageRequest = registerImageRequest.
                    withBlockDeviceMappings(
                            new BlockDeviceMapping().
                                    withDeviceName(rootDeviceName.get()).
                                    withEbs(new EbsBlockDevice().
                                            withSnapshotId(testSnapshot.get().getSnapshotId())),
                            new BlockDeviceMapping().
                                    withDeviceName("/dev/sdb").
                                    withVirtualName("ephemeral0"),
                            new BlockDeviceMapping().
                                    withDeviceName("/dev/sdc").
                                    withVirtualName("ephemeral1"),
                            new BlockDeviceMapping().
                                    withDeviceName("/dev/sdd").
                                    withVirtualName("ephemeral2"),
                            new BlockDeviceMapping().
                                    withDeviceName("/dev/sde").
                                    withVirtualName("ephemeral3"));
        }

        RegisterImageResult registerImageResult = ec2Client.registerImage(registerImageRequest);

        String imageId = registerImageResult.getImageId();

        DescribeImagesRequest describeImagesRequest = new DescribeImagesRequest().
                withImageIds(imageId);

        try
        {
            while (true)
            {
                log.info("Sleeping for " + sleep.get() + " ms");
                Thread.sleep(sleep.get());
                DescribeImagesResult describeImagesResult = ec2Client.describeImages(describeImagesRequest);
                if (describeImagesResult.getImages().isEmpty())
                {
                    return Optional.absent();
                }
                Image image = describeImagesResult.getImages().get(0);
                String state = image.getState(); 
                log.info("Image state = " + state);
                if ("pending".equals(state))
                {
                    continue;
                }
                if (!"available".equals(state))
                {
                    return Optional.absent();
                }
                return Optional.fromNullable(image);
            }
        }
        catch (InterruptedException e)
        {
            return Optional.absent();
        }
    }
}

