
package com.dowdandassociates.gentoo.bootstrap;

import java.util.ArrayList;
import java.util.List;

import com.amazonaws.services.ec2.model.AuthorizeSecurityGroupIngressRequest;
import com.amazonaws.services.ec2.model.DescribeSecurityGroupsRequest;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.IpPermission;

import com.netflix.config.DynamicIntProperty;
import com.netflix.config.DynamicPropertyFactory;
import com.netflix.config.DynamicStringProperty;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ArchaiusSecurityGroupCidr implements SecurityGroup
{
    private static Logger log = LoggerFactory.getLogger(ArchaiusSecurityGroupCidr.class);

    private static final String SECURITY_GROUP_NAME_PROPERTY = "com.dowdandassociates.gentoo.bootstrap.SecurityGroup.name";
    private static final String SECURITY_GROUP_DESCRIPTION_PROPERTY = "com.dowdandassociates.gentoo.bootstrap.SecurityGroup.description";
    private static final String SECURITY_GROUP_CIDR_PROPERTY = "com.dowdandassociates.gentoo.bootstrap.SecurityGroup.cidr";
    private static final String SECURITY_GROUP_PORT_PROPERTY = "com.dowdandassociates.gentoo.bootstrap.SecurityGroup.port";

    private static final String DEFAULT_SECURITY_GROUP_NAME = "gentoo-bootstrap";
    private static final String DEFAULT_SECURITY_GROUP_DESCRIPTION = "Gentoo Bootstrap";
    private static final String DEFAULT_SECURITY_GROUP_CIDR = "0.0.0.0/0";
    private static final int DEFAULT_SECURITY_GROUP_PORT = 22;

    private DynamicStringProperty cidr;
    private DynamicStringProperty description;
    private DynamicStringProperty name;
    private DynamicIntProperty port;

    public ArchaiusSecurityGroupCidr()
    {
        name = DynamicPropertyFactory.getInstance().getStringProperty(SECURITY_GROUP_NAME_PROPERTY, DEFAULT_SECURITY_GROUP_NAME);
        description = DynamicPropertyFactory.getInstance().getStringProperty(SECURITY_GROUP_DESCRIPTION_PROPERTY, DEFAULT_SECURITY_GROUP_DESCRIPTION);
        cidr = DynamicPropertyFactory.getInstance().getStringProperty(SECURITY_GROUP_CIDR_PROPERTY, DEFAULT_SECURITY_GROUP_CIDR);
        port = DynamicPropertyFactory.getInstance().getIntProperty(SECURITY_GROUP_PORT_PROPERTY, DEFAULT_SECURITY_GROUP_PORT);
    }

    public String getName()
    {
        return name.get();
    }

    public String getDescription()
    {
        return description.get();
    }

    public DescribeSecurityGroupsRequest getAuthorizationCheckRequest()
    {
        return new DescribeSecurityGroupsRequest().
                withFilters(new Filter().withName("group-name").withValues(name.get()),
                            new Filter().withName("ip-permission.cidr").withValues(cidr.get()),
                            new Filter().withName("ip-permission.from-port").withValues(new Integer(port.get()).toString()),
                            new Filter().withName("ip-permission.to-port").withValues(new Integer(port.get()).toString()),
                            new Filter().withName("ip-permission.protocol").withValues("tcp"));
    }

    public AuthorizeSecurityGroupIngressRequest getAuthorizationRequest()
    {
        return new AuthorizeSecurityGroupIngressRequest().
                withGroupName(name.get()).
                withIpPermissions(new IpPermission().
                        withIpProtocol("tcp").
                        withFromPort(port.get()).
                        withToPort(port.get()).
                        withIpRanges(cidr.get()));
    }
}

