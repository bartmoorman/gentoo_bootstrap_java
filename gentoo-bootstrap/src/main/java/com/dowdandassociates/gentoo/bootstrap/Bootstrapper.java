
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

import com.google.inject.Inject;
import com.google.inject.name.Named;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Bootstrapper
{
    private static Logger log = LoggerFactory.getLogger(Bootstrapper.class);

    private AmazonMachineImage bootstrapImage;
    private boolean builtKeyPair;
    private AmazonEC2 ec2Client;
    private AmazonKernelImage kernel;
    private KeyPair keyPair;
    private SecurityGroup securityGroup;

    @Inject
    public void setEC2Client(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    @Inject
    public void setKeyPair(KeyPair keyPair)
    {
        this.keyPair = keyPair;
    }

    @Inject
    public void setSecurityGroup(SecurityGroup securityGroup)
    {
        this.securityGroup = securityGroup;
    }

    @Inject
    public void setBootstrapImage(@Named("Bootstrap Image") AmazonMachineImage bootstrapImage)
    {
        this.bootstrapImage = bootstrapImage;
    }

    @Inject
    public void setKernel(AmazonKernelImage kernel)
    {
        this.kernel = kernel;
    }

    public void execute()
    {
//        checkKeyPair();
//        checkSecurityGroup();
        String bootstrapImageId = bootstrapImage.getImageId();
        log.info("bootstrap image id: " + bootstrapImageId);
        String kernelId = kernel.getImageId();
        log.info("kernel id: " + kernelId);
    }

    private void checkKeyPair()
    {
        log.info("Checking if key pair \"" + keyPair.getName() + "\" exists");

        if (ec2Client.describeKeyPairs(new DescribeKeyPairsRequest().
                withFilters(new Filter().withName("key-name").withValues(keyPair.getName()))).getKeyPairs().isEmpty())
        {
            log.info("Building key pair");

            CreateKeyPairResult createResult = ec2Client.createKeyPair(new CreateKeyPairRequest().
                    withKeyName(keyPair.getName()));
        
            try
            {
                log.info("Saving pem file to \"" + keyPair.getFilename() + "\"");

                BufferedWriter outfile = new BufferedWriter(new FileWriter(keyPair.getFilename()));

                try
                {
                    outfile.write(createResult.getKeyPair().getKeyMaterial());
                }
                catch (IOException ioe)
                {
                    String message = "Error writing to file: " + keyPair.getFilename();
                    log.error(message, ioe);
                    throw new RuntimeException(message, ioe);
                }
                finally
                {
                    outfile.close();
                }
            }
            catch (IOException ioe)
            {
                String message = "Error opening file: " + keyPair.getFilename();
                log.error(message, ioe);
                throw new RuntimeException(message, ioe);
            }

            builtKeyPair = true;
            log.info("Key pair built");
        }
        else
        {
            builtKeyPair = false;
            log.info("Key pair exists");
        }
    }

    private void checkSecurityGroup()
    {
        log.info("Check if security group \"" + securityGroup.getName() + "\" is set up.");

        if (ec2Client.describeSecurityGroups(securityGroup.getAuthorizationCheckRequest()).getSecurityGroups().isEmpty())
        {
            log.info("Security group is not set up. Checking if it exists.");
            if (ec2Client.describeSecurityGroups(new DescribeSecurityGroupsRequest().
                    withFilters(new Filter().withName("group-name").withValues(securityGroup.getName()))).getSecurityGroups().isEmpty())
            {
                log.info("Security group does not exist. Creating it.");
                ec2Client.createSecurityGroup(new CreateSecurityGroupRequest().
                        withGroupName(securityGroup.getName()).
                        withDescription(securityGroup.getDescription()));
            }

            log.info("Setting ingress rules for security group");
            ec2Client.authorizeSecurityGroupIngress(securityGroup.getAuthorizationRequest());
        }
        log.info("Security group set up");
    }
}

