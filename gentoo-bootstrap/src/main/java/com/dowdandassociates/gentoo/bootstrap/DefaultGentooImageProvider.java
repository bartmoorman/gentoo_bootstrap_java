/*
 *
 * DefaultGentooImageProvider.java
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
import com.amazonaws.services.ec2.model.CreateSnapshotRequest;
import com.amazonaws.services.ec2.model.CreateSnapshotResult;
import com.amazonaws.services.ec2.model.DeleteVolumeRequest;
import com.amazonaws.services.ec2.model.DescribeInstancesRequest;
import com.amazonaws.services.ec2.model.DescribeInstancesResult;
import com.amazonaws.services.ec2.model.DescribeSnapshotsRequest;
import com.amazonaws.services.ec2.model.DescribeSnapshotsResult;
import com.amazonaws.services.ec2.model.DescribeVolumesRequest;
import com.amazonaws.services.ec2.model.DescribeVolumesResult;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Snapshot;
import com.amazonaws.services.ec2.model.TerminateInstancesRequest;
import com.amazonaws.services.ec2.model.TerminateInstancesResult;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultGentooImageProvider implements Provider<Optional<Image>>
{
    private static Logger log = LoggerFactory.getLogger(DefaultGentooImageProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.GentooImage.checkInstanceSleep")
    private Supplier<Long> instanceSleep = Suppliers.ofInstance(10000L);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.GentooImage.checkVolumeSleep")
    private Supplier<Long> volumeSleep = Suppliers.ofInstance(10000L);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.GentooImage.checkSnapshotSleep")
    private Supplier<Long> snapshotSleep = Suppliers.ofInstance(10000L);

    private AmazonEC2 ec2Client;
    private TestResultInformation testResultInformation;

    @Inject
    public DefaultGentooImageProvider(AmazonEC2 ec2Client, TestResultInformation testResultInformation)
    {
        this.ec2Client = ec2Client;
        this.testResultInformation = testResultInformation;
    }

    public Optional<Image> get()
    {
        TestInstanceInformation instanceInfo = testResultInformation.getInstanceInfo();
        Optional<Instance> instance = instanceInfo.getInstance();
        Optional<Image> image = instanceInfo.getImage();
        Optional<Integer> exitStatus = testResultInformation.getExitStatus();

        if (!instance.isPresent())
        {
            log.info("Instance is absent");
            return Optional.absent();
        }

        String instanceId = instance.get().getInstanceId();

        TerminateInstancesResult terminateInstancesResult = ec2Client.terminateInstances(new TerminateInstancesRequest().
                withInstanceIds(instanceId));

        if (!exitStatus.isPresent())
        {
            log.info("Exit status is absent");
            return Optional.absent();
        }

        log.info("exit status = " + exitStatus.get());

        if (0 != exitStatus.get())
        {
            return Optional.absent();
        }

        if (!image.isPresent())
        {
            log.info("Image is absent");
        }
        else
        {
            log.info("Image is present");
            log.info("Image id is " + image.get().getImageId());
        }
        
        return image;
    }
}

