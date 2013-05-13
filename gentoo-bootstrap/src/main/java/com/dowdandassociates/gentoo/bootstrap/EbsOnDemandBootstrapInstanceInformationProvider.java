/*
 *
 * EbsOnDemandBootstrapInstanceInformationProvider.java
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
import com.amazonaws.services.ec2.model.CreateVolumeRequest;
import com.amazonaws.services.ec2.model.CreateVolumeResult;
import com.amazonaws.services.ec2.model.DescribeVolumesRequest;
import com.amazonaws.services.ec2.model.DescribeVolumesResult;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;
import com.google.inject.name.Named;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class EbsOnDemandBootstrapInstanceInformationProvider extends AbstractOnDemandBootstrapInstanceInformationProvider
{
    private static Logger log = LoggerFactory.getLogger(EbsOnDemandBootstrapInstanceInformationProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.volumeSize")
    private Supplier<Integer> volumeSize = Suppliers.ofInstance(10);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.checkVolumeSleep")
    private Supplier<Long> sleep = Suppliers.ofInstance(10000L);

    @Inject
    public EbsOnDemandBootstrapInstanceInformationProvider(
            AmazonEC2 ec2Client,
            @Named("Bootstrap Image") Optional<Image> bootstrapImage,
            KeyPairInformation keyPairInformation,
            SecurityGroupInformation securityGroupInformation,
            BlockDeviceInformation blockDeviceInformation)
    {
        super(ec2Client, bootstrapImage, keyPairInformation, securityGroupInformation, blockDeviceInformation);
    }

    @Override
    protected Optional<Volume> generateVolume(Optional<Instance> instance)
    {
        if (!instance.isPresent())
        {
            return Optional.absent();
        }

        log.info("AvailabilityZone=" + instance.get().getPlacement().getAvailabilityZone());
        log.info("Size=" + volumeSize.get().toString());

        CreateVolumeResult createVolumeResult = getEc2Client().createVolume(new CreateVolumeRequest().
                withAvailabilityZone(instance.get().getPlacement().getAvailabilityZone()).
                withSize(volumeSize.get()));

        log.info("volume id = " + createVolumeResult.getVolume().getVolumeId());
        DescribeVolumesRequest describeVolumesRequest = new DescribeVolumesRequest().
                withVolumeIds(createVolumeResult.getVolume().getVolumeId());

        try
        {
            while (true)
            {
                log.info("Sleeping for " + sleep.get().toString() + " ms");
                Thread.sleep(sleep.get());
                DescribeVolumesResult describeVolumesResult = getEc2Client().describeVolumes(describeVolumesRequest);

                Volume volume = describeVolumesResult.getVolumes().get(0);
                String state = volume.getState();

                log.info("volume state = " +  state);

                if ("creating".equals(state))
                {
                    continue;
                }

                if (!"available".equals(state))
                {
                    return Optional.absent();
                }

                return Optional.fromNullable(volume);
            }

        }
        catch (InterruptedException e)
        {
            return Optional.absent();
        }
    }
}

