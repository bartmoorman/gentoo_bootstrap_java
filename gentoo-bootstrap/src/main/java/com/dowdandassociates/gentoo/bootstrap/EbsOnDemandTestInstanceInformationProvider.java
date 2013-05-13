/*
 *
 * EbsOnDemandTestInstanceInformationProvider.java
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

import com.google.inject.Inject;
import com.google.inject.name.Named;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class EbsOnDemandTestInstanceInformationProvider extends AbstractTestInstanceInformationProvider
{
    private static Logger log = LoggerFactory.getLogger(EbsOnDemandTestInstanceInformationProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestInstance.checkInstanceSleep")
    private Supplier<Long> sleep = Suppliers.ofInstance(10000L);

    @Inject
    public EbsOnDemandTestInstanceInformationProvider(
            AmazonEC2 ec2Client,
            @Named("Test Image") Optional<Image> testImage,
            KeyPairInformation keyPairInformation,
            SecurityGroupInformation securityGroupInformation)
    {
        super(ec2Client, testImage, keyPairInformation, securityGroupInformation);
    }

    @Override
    protected Optional<Instance> generateInstance()
    {
        return InstanceUtils.onDemandInstance(
                getEc2Client(),
                getTestImage(),
                1,
                1,
                getSecurityGroupInformation(),
                getKeyPairInformation(),
                getInstanceType(),
                getAvailabilityZone(),
                sleep.get());
    }
}

