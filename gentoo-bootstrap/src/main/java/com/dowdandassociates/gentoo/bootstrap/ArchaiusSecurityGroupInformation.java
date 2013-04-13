
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
//import com.google.inject.Singleton;

import com.netflix.config.DynamicIntProperty;
import com.netflix.config.DynamicPropertyFactory;
import com.netflix.config.DynamicStringProperty;
import com.netflix.governator.guice.lazy.FineGrainedLazySingleton;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

//@Singleton
@FineGrainedLazySingleton
public class ArchaiusSecurityGroupInformation implements SecurityGroupInformation
{
    private static Logger log = LoggerFactory.getLogger(ArchaiusSecurityGroupInformation.class);

    private static final String SECURITY_GROUP_NAME_PROPERTY = "com.dowdandassociates.gentoo.bootstrap.SecurityGroup.name";
    private static final String SECURITY_GROUP_DESCRIPTION_PROPERTY = "com.dowdandassociates.gentoo.bootstrap.SecurityGroup.description";
    private static final String SECURITY_GROUP_CIDR_PROPERTY = "com.dowdandassociates.gentoo.bootstrap.SecurityGroup.cidr";
    private static final String SECURITY_GROUP_PORT_PROPERTY = "com.dowdandassociates.gentoo.bootstrap.SecurityGroup.port";

    private static final String DEFAULT_SECURITY_GROUP_NAME = "gentoo-bootstrap";
    private static final String DEFAULT_SECURITY_GROUP_DESCRIPTION = "Gentoo Bootstrap";
    private static final String DEFAULT_SECURITY_GROUP_CIDR = "0.0.0.0/0";
    private static final int DEFAULT_SECURITY_GROUP_PORT = 22;

    private AmazonEC2 ec2Client;
    private String groupName;
    private String groupId;

    @Inject
    public ArchaiusSecurityGroupInformation(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
        groupName = DynamicPropertyFactory.getInstance().getStringProperty(SECURITY_GROUP_NAME_PROPERTY, DEFAULT_SECURITY_GROUP_NAME).get();
    }

    @PostConstruct
    public void setup()
    {
        String description = DynamicPropertyFactory.getInstance().getStringProperty(SECURITY_GROUP_DESCRIPTION_PROPERTY, DEFAULT_SECURITY_GROUP_DESCRIPTION).get();
        String cidr = DynamicPropertyFactory.getInstance().getStringProperty(SECURITY_GROUP_CIDR_PROPERTY, DEFAULT_SECURITY_GROUP_CIDR).get();
        Integer port = DynamicPropertyFactory.getInstance().getIntProperty(SECURITY_GROUP_PORT_PROPERTY, DEFAULT_SECURITY_GROUP_PORT).get();

        log.info("Checking if security group \"" + groupName + "\" is set up.");

        DescribeSecurityGroupsResult describeResult = ec2Client.describeSecurityGroups(new DescribeSecurityGroupsRequest().
                withFilters(new Filter().withName("group-name").withValues(groupName),
                            new Filter().withName("ip-permission.cidr").withValues(cidr),
                            new Filter().withName("ip-permission.from-port").withValues(port.toString()),
                            new Filter().withName("ip-permission.to-port").withValues(port.toString()),
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

