
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

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Bootstrapper
{
    private static Logger log = LoggerFactory.getLogger(Bootstrapper.class);

    private boolean builtKeyPair;
    private AmazonEC2 ec2Client;
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

    public void execute()
    {
        checkKeyPair();
        checkSecurityGroup();
    }

    private void checkKeyPair()
    {
        if (ec2Client.describeKeyPairs(new DescribeKeyPairsRequest().
                withFilters(new Filter().withName("key-name").withValues(keyPair.getName()))).getKeyPairs().isEmpty())
        {
            CreateKeyPairResult createResult = ec2Client.createKeyPair(new CreateKeyPairRequest().
                    withKeyName(keyPair.getName()));
        
            try
            {
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
        }
        else
        {
            builtKeyPair = false;
        }
    }

    private void checkSecurityGroup()
    {
        // Check if the group is setup
        if (ec2Client.describeSecurityGroups(securityGroup.getAuthorizationCheckRequest()).getSecurityGroups().isEmpty())
        {
            // The group is not setup
            // Check if the group exists
            if (ec2Client.describeSecurityGroups(new DescribeSecurityGroupsRequest().
                    withFilters(new Filter().withName("group-name").withValues(securityGroup.getName()))).getSecurityGroups().isEmpty())
            {
                // The group does not exist
                // Create group
                ec2Client.createSecurityGroup(new CreateSecurityGroupRequest().
                        withGroupName(securityGroup.getName()).
                        withDescription(securityGroup.getDescription()));
            }

            // Setup Group
            ec2Client.authorizeSecurityGroupIngress(securityGroup.getAuthorizationRequest());
        }
    }
}

