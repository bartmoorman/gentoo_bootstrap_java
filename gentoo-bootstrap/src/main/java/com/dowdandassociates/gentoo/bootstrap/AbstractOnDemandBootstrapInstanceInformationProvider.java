/*
 *
 * AbstractOnDemandBootstrapInstanceInformationProvider.java
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
import com.amazonaws.services.ec2.model.DescribeInstancesRequest;
import com.amazonaws.services.ec2.model.DescribeInstancesResult;
import com.amazonaws.services.ec2.model.DescribeInstanceStatusRequest;
import com.amazonaws.services.ec2.model.DescribeInstanceStatusResult;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.InstanceStatus;
import com.amazonaws.services.ec2.model.Placement;
import com.amazonaws.services.ec2.model.RunInstancesRequest;
import com.amazonaws.services.ec2.model.RunInstancesResult;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractOnDemandBootstrapInstanceInformationProvider extends AbstractBootstrapInstanceInformationProvider
{
    private static Logger log = LoggerFactory.getLogger(AbstractOnDemandBootstrapInstanceInformationProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.checkInstanceSleep")
    private Supplier<Long> sleep = Suppliers.ofInstance(10000L);

    public AbstractOnDemandBootstrapInstanceInformationProvider(
            AmazonEC2 ec2Client,
            Optional<Image> bootstrapImage,
            KeyPairInformation keyPairInformation,
            SecurityGroupInformation securityGroupInformation,
            BlockDeviceInformation blockDeviceInformation)
    {
        super(ec2Client, bootstrapImage, keyPairInformation, securityGroupInformation, blockDeviceInformation);
    }

    @Override
    protected Optional<Instance> generateInstance()
    {
        return InstanceUtils.onDemandInstance(
                getEc2Client(),
                getBootstrapImage(),
                1,
                1,
                getSecurityGroupInformation(),
                getKeyPairInformation(),
                getInstanceType(),
                getAvailabilityZone(),
                sleep.get());
/*
        if (!getBootstrapImage().isPresent())
        {
            return Optional.absent();
        }

        RunInstancesRequest runInstancesRequest = new RunInstancesRequest().
                withImageId(getBootstrapImage().get().getImageId()).
                withMinCount(1).
                withMaxCount(1).
                withSecurityGroups(getSecurityGroupInformation().getGroupName()).
                withKeyName(getKeyPairInformation().getName());

        log.info("ImageId=" + getBootstrapImage().get().getImageId());
        log.info("MinCount=1");
        log.info("MaxCount=1");
        log.info("SecurityGroups.1=" + getSecurityGroupInformation().getGroupName());
        log.info("KeyName=" + getKeyPairInformation().getName());

        if (getInstanceType().isPresent())
        {
            runInstancesRequest.setInstanceType(getInstanceType().get());
            log.info("InstanceType=" + getInstanceType().get()); 
        }

        if (getAvailabilityZone().isPresent())
        {
            runInstancesRequest.setPlacement(new Placement().
                    withAvailabilityZone(getAvailabilityZone().get()));

            log.info("Placement.AvailabilityZone=" + getAvailabilityZone().get());
        }

        RunInstancesResult runInstancesResult = getEc2Client().runInstances(runInstancesRequest);

        DescribeInstanceStatusRequest describeInstanceStatusRequest = new DescribeInstanceStatusRequest().
                withInstanceIds(runInstancesResult.getReservation().getInstances().get(0).getInstanceId());

        try
        {
            while (true)
            {
                log.info("Sleeping for " + sleep.get().toString() + " ms");
                Thread.sleep(sleep.get());

                DescribeInstanceStatusResult describeInstanceStatusResult = getEc2Client().describeInstanceStatus(describeInstanceStatusRequest);
                if (describeInstanceStatusResult.getInstanceStatuses().isEmpty())
                {
                    continue;
                }
                InstanceStatus instance = describeInstanceStatusResult.getInstanceStatuses().get(0);

                String instanceState = instance.getInstanceState().getName();

                log.info("instanceState = " + instanceState);

                if ("pending".equals(instanceState))
                {
                    continue;
                }

                if (!"running".equals(instanceState))
                {
                    return Optional.absent();
                }

                String instanceStatus = instance.getInstanceStatus().getStatus();
                String systemStatus = instance.getSystemStatus().getStatus();

                log.info("instanceStatus = " + instanceStatus);
                log.info("systemStatus = " + systemStatus);

                if ("impaired".equals(instanceStatus))
                {
                    return Optional.absent();
                }

                if ("impaired".equals(systemStatus))
                {
                    return Optional.absent();
                }

                if (!"ok".equals(instanceStatus))
                {
                    continue;
                }

                if (!"ok".equals(systemStatus))
                {
                    continue;
                }

                break;
            }
        }
        catch (InterruptedException e)
        {
            return Optional.absent();
        }

        DescribeInstancesResult describeInstancesResult = getEc2Client().describeInstances(new DescribeInstancesRequest().
                withInstanceIds(runInstancesResult.getReservation().getInstances().get(0).getInstanceId()));

        return Optional.fromNullable(describeInstancesResult.getReservations().get(0).getInstances().get(0));
*/
    }
}

