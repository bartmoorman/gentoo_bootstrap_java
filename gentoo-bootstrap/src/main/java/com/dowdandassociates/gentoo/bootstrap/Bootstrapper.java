
package com.dowdandassociates.gentoo.bootstrap;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.CreateKeyPairRequest;
import com.amazonaws.services.ec2.model.CreateKeyPairResult;
import com.amazonaws.services.ec2.model.DescribeKeyPairsRequest;
import com.amazonaws.services.ec2.model.DescribeKeyPairsResult;
import com.amazonaws.services.ec2.model.Filter;

import com.google.inject.Inject;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Bootstrapper
{
    private static Logger log = LoggerFactory.getLogger(Bootstrapper.class);

    private AmazonEC2 ec2Client;
    private KeyPair keyPair;
    private boolean builtKeyPair;

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

    public void execute()
    {
        checkKeyPair();
    }

    private void checkKeyPair()
    {
        DescribeKeyPairsResult describeResult = ec2Client.describeKeyPairs(new DescribeKeyPairsRequest().
                withFilters(new Filter().
                        withName("key-name").
                        withValues(keyPair.getName())));
        if (describeResult.getKeyPairs().isEmpty())
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
}

