
package com.dowdandassociates.gentoo.bootstrap;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.CreateKeyPairRequest;
import com.amazonaws.services.ec2.model.CreateKeyPairResult;
import com.amazonaws.services.ec2.model.CreateSecurityGroupRequest;
import com.amazonaws.services.ec2.model.DescribeKeyPairsRequest;
import com.amazonaws.services.ec2.model.DescribeKeyPairsResult;
import com.amazonaws.services.ec2.model.DescribeSecurityGroupsRequest;
import com.amazonaws.services.ec2.model.DescribeSecurityGroupsResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Image;
import com.amazonaws.services.ec2.model.Instance;

import com.google.inject.Inject;
import com.google.inject.name.Named;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Bootstrapper
{
    private static Logger log = LoggerFactory.getLogger(Bootstrapper.class);

    private Image bootstrapImage;
    private boolean builtKeyPair;
    private AmazonEC2 ec2Client;
    private Image kernel;
    private KeyPairInformation keyPair;
    private SecurityGroupInformation securityGroup;
    private Instance bootstrapInstance;

    @Inject
    public void setBootstrapImage(@Named("Bootstrap Image") Image bootstrapImage)
    {
        this.bootstrapImage = bootstrapImage;
    }

    @Inject
    public void setEC2Client(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    @Inject
    public void setKernel(@Named("Kernel Image") Image kernel)
    {
        this.kernel = kernel;
    }

    @Inject
    public void setKeyPair(KeyPairInformation keyPair)
    {
        this.keyPair = keyPair;
    }

    @Inject
    public void setSecurityGroup(SecurityGroupInformation securityGroup)
    {
        this.securityGroup = securityGroup;
    }

    @Inject
    public void setBootstrapInstance(@Named("Bootstrap Instance") Instance bootstrapInstance)
    {
        this.bootstrapInstance = bootstrapInstance;
    }

    public void execute()
    {
        log.info("key pair name: " + keyPair.getName());
        log.info("key pair filename: " + keyPair.getFilename());
        log.info("security group name: " + securityGroup.getGroupName());
        log.info("security group id: " + securityGroup.getGroupId());
        log.info("bootstrap image id: " + bootstrapImage.getImageId());
        log.info("kernel id: " + kernel.getImageId());
        log.info("bootstrap instance: " + ((bootstrapInstance != null) ? bootstrapInstance.getInstanceId() : "null"));
    }

}

