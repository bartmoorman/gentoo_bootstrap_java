/*
 *
 * DefaultSecurityGroupInformation.java
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

import javax.annotation.PostConstruct;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.AuthorizeSecurityGroupIngressRequest;
import com.amazonaws.services.ec2.model.CreateSecurityGroupRequest;
import com.amazonaws.services.ec2.model.DescribeSecurityGroupsRequest;
import com.amazonaws.services.ec2.model.DescribeSecurityGroupsResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.IpPermission;

import com.google.inject.Inject;

import com.netflix.governator.annotations.Configuration;
import com.netflix.governator.guice.lazy.FineGrainedLazySingleton;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@FineGrainedLazySingleton
public class DefaultSecurityGroupInformation implements SecurityGroupInformation
{
    private static Logger log = LoggerFactory.getLogger(DefaultSecurityGroupInformation.class);

    private AmazonEC2 ec2Client;
    private String groupId;

    @Configuration("com.dowdandassociates.gentoo.bootstrap.SecurityGroup.name")
    private String groupName = "gentoo-bootstrap";

    @Configuration("com.dowdandassociates.gentoo.bootstrap.SecurityGroup.description")
    private String description = "Gentoo Bootstrap";

    @Configuration("com.dowdandassociates.gentoo.bootstrap.SecurityGroup.cidr")
    private String cidr = "0.0.0.0/0";

    @Configuration("com.dowdandassociates.gentoo.bootstrap.SecurityGroup.port")
    private int port = 22;

    @Inject
    public DefaultSecurityGroupInformation(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    @PostConstruct
    private void setup()
    {
        log.info("Checking if security group \"" + groupName + "\" is set up.");

        DescribeSecurityGroupsResult describeResult = ec2Client.describeSecurityGroups(new DescribeSecurityGroupsRequest().
                withFilters(new Filter().withName("group-name").withValues(groupName),
                            new Filter().withName("ip-permission.cidr").withValues(cidr),
                            new Filter().withName("ip-permission.from-port").withValues(new Integer(port).toString()),
                            new Filter().withName("ip-permission.to-port").withValues(new Integer(port).toString()),
                            new Filter().withName("ip-permission.protocol").withValues("tcp")));

        if (!describeResult.getSecurityGroups().isEmpty())
        {
            groupId = describeResult.getSecurityGroups().get(0).getGroupId();
        }
        else
        {
            log.info("Security group \"" + groupName + "\" is not set up. Checking if it exists.");
            describeResult = ec2Client.describeSecurityGroups(new DescribeSecurityGroupsRequest().
                    withFilters(new Filter().withName("group-name").withValues(groupName)));
            if (!describeResult.getSecurityGroups().isEmpty())
            {
                log.info("Security group \"" + groupName + "\" exists.");
                groupId = describeResult.getSecurityGroups().get(0).getGroupId();
            }
            else
            {
                log.info("Security group \"" + groupName + "\" does not exists. Creating it.");
                groupId = ec2Client.createSecurityGroup(new CreateSecurityGroupRequest().
                        withGroupName(groupName).
                        withDescription(description)).getGroupId();
            }

            log.info("Authorizing ingress rules for \"" + groupName + "\".");
            ec2Client.authorizeSecurityGroupIngress(new AuthorizeSecurityGroupIngressRequest().
                withGroupName(groupName).
                withIpPermissions(new IpPermission().
                        withIpProtocol("tcp").
                        withFromPort(port).
                        withToPort(port).
                        withIpRanges(cidr)));
        }

        log.info("Security group \"" + groupName + "\" is set up.");
    }

    @Override
    public String getGroupName()
    {
        return groupName;
    }

    @Override
    public String getGroupId()
    {
        return groupId;
    }
}

