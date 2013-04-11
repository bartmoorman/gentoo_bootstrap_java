
package com.dowdandassociates.gentoo.bootstrap;

import java.util.List;

import com.amazonaws.services.ec2.model.AuthorizeSecurityGroupIngressRequest;
import com.amazonaws.services.ec2.model.DescribeSecurityGroupsRequest;

public interface SecurityGroup
{
    public String getName();
    public String getDescription();
    public DescribeSecurityGroupsRequest getAuthorizationCheckRequest();
    public AuthorizeSecurityGroupIngressRequest getAuthorizationRequest();
}

