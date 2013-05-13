/*
 *
 * InstanceUtils.java
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

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class InstanceUtils
{
    private static Logger log = LoggerFactory.getLogger(InstanceUtils.class);

    public static Optional<Instance> onDemandInstance(
            AmazonEC2 ec2Client,
            Optional<Image> image,
            Integer minCount,
            Integer maxCount,
            SecurityGroupInformation securityGroupInformation,
            KeyPairInformation keyPairInformation,
            Optional<String> instanceType,
            Optional<String> availabilityZone,
            Long sleep)
    {
        if (!image.isPresent())
        {
            return Optional.absent();
        }

        RunInstancesRequest runInstancesRequest = new RunInstancesRequest().
                withImageId(image.get().getImageId()).
                withMinCount(minCount).
                withMaxCount(maxCount).
                withSecurityGroups(securityGroupInformation.getGroupName()).
                withKeyName(keyPairInformation.getName());

        log.info("ImageId=" + image.get().getImageId());
        log.info("MinCount=" + minCount);
        log.info("MaxCount=" + maxCount);
        log.info("SecurityGroups.1=" + securityGroupInformation.getGroupName());
        log.info("KeyName=" + keyPairInformation.getName());

        if (instanceType.isPresent())
        {
            runInstancesRequest.setInstanceType(instanceType.get());
            log.info("InstanceType=" + instanceType.get()); 
        }

        if (availabilityZone.isPresent())
        {
            runInstancesRequest.setPlacement(new Placement().
                    withAvailabilityZone(availabilityZone.get()));

            log.info("Placement.AvailabilityZone=" + availabilityZone.get());
        }

        RunInstancesResult runInstancesResult = ec2Client.runInstances(runInstancesRequest);

        DescribeInstanceStatusRequest describeInstanceStatusRequest = new DescribeInstanceStatusRequest().
                withInstanceIds(runInstancesResult.getReservation().getInstances().get(0).getInstanceId());

        try
        {
            while (true)
            {
                log.info("Sleeping for " + sleep + " ms");
                Thread.sleep(sleep);

                DescribeInstanceStatusResult describeInstanceStatusResult = ec2Client.describeInstanceStatus(describeInstanceStatusRequest);
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

        DescribeInstancesResult describeInstancesResult = ec2Client.describeInstances(new DescribeInstancesRequest().
                withInstanceIds(runInstancesResult.getReservation().getInstances().get(0).getInstanceId()));

        return Optional.fromNullable(describeInstancesResult.getReservations().get(0).getInstances().get(0));
    }
}

