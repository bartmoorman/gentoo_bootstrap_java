/*
 *
 * Bootstrapper.java
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

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

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
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;

import com.google.inject.Inject;
import com.google.inject.name.Named;

import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;

import freemarker.template.Configuration;
import freemarker.template.Template;
import freemarker.template.TemplateException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Bootstrapper
{
    private static Logger log = LoggerFactory.getLogger(Bootstrapper.class);
/*
    private Optional<Image> bootstrapImage;
    private AmazonEC2 ec2Client;
    private Optional<Image> kernel;
    private KeyPairInformation keyPair;
    private SecurityGroupInformation securityGroup;
*/
    private Optional<Image> gentooImage;
/*
    @Inject
    public void setBootstrapImage(@Named("Bootstrap Image") Optional<Image> bootstrapImage)
    {
        this.bootstrapImage = bootstrapImage;
    }

    @Inject
    public void setEC2Client(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    @Inject
    public void setKernel(@Named("Kernel Image") Optional<Image> kernel)
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
    public void setBootstrapResultInformation(BootstrapResultInformation bootstrapResultInformation)
    {
        this.bootstrapResultInformation = bootstrapResultInformation;
    }
*/

    @Inject
    public void setGentooImage(@Named("Gentoo Image") Optional<Image> gentooImage)
    {
        this.gentooImage =  gentooImage;
    }

    public void execute()
    {
        log.info("gentoo image id: " + ((gentooImage.isPresent()) ? gentooImage.get().getImageId() : "absent"));

/*
        log.info("key pair name: " + keyPair.getName());
        log.info("key pair filename: " + keyPair.getFilename());
        log.info("security group name: " + securityGroup.getGroupName());
        log.info("security group id: " + securityGroup.getGroupId());
        log.info("bootstrap image id: " + bootstrapImage.get().getImageId());
        log.info("kernel id: " + kernel.get().getImageId());

        Optional<Instance> bootstrapInstance = bootstrapResultInformation.getInstanceInfo().getInstance();
        log.info("bootstrap instance: " + ((bootstrapInstance.isPresent()) ? bootstrapInstance.get().getInstanceId() : "absent"));

        Optional<Volume> bootstrapVolume = bootstrapResultInformation.getInstanceInfo().getVolume();
        log.info("bootstrap volume: " + ((bootstrapVolume.isPresent()) ? bootstrapVolume.get().getVolumeId() : "absent"));

        Optional<Integer> exitStatus = bootstrapResultInformation.getExitStatus();
        log.info("exitStatus: " + ((exitStatus.isPresent()) ? exitStatus.get().toString() : "absent"));
*/
/*
        String filename = "/tmp/hello.sh";
        StringBuilder contentBuf = new StringBuilder();

        contentBuf.append("#!/bin/bash");
        contentBuf.append('\n');

        contentBuf.append('\n');

        contentBuf.append("echo \"hello, world\"");
        contentBuf.append('\n');

        contentBuf.append("echo \"hello, file\" > /tmp/hello.txt");
        contentBuf.append('\n');

        String content = contentBuf.toString();

        String sudoCommand = "/tmp/hello.sh";

        try
        {
            log.info("filename = " + filename);
            log.info("content = " + content);

            log.info("Openning channel");

            ChannelExec channel = (ChannelExec)bootstrapSession.openChannel("exec");

            log.info("Setting command");

            channel.setCommand("scp -t " + filename);

            log.info("Getting input and output streams");

            OutputStream out = channel.getOutputStream();
            InputStream in = channel.getInputStream();

            log.info("Connecting channel");

            channel.connect();

            log.info("Check ack after connect");
            if (checkAck(in) != 0)
            {
                throw new IOException("checkAck failed after connect");
            }

            StringBuilder command = new StringBuilder();
            command.append("C0755 ");
            command.append(content.length());
            command.append(' ');
            if (filename.lastIndexOf('/') > 0)
            {
                command.append(filename.substring(filename.lastIndexOf('/') + 1));
            }
            else
            {
                command.append(filename);
            }
            command.append('\n');
            log.info("scp command: " + command.toString());
            log.info("writing scp command");
            out.write(command.toString().getBytes());
            out.flush();

            log.info("check ack after scp command");
            if (checkAck(in) != 0)
            {
                throw new IOException("checkAck failed after scp command");
            }

            log.info("writing content");
            out.write(content.getBytes());
            byte[] buf = new byte[1024];
            buf[0] = 0;
            out.write(buf, 0, 1);
            out.flush();

            log.info("check after writing content");
            if (checkAck(in) != 0)
            {
                throw new IOException("checkAck failed after file write");
            }

            log.info("closing scp connection");
            in.close();
            out.close();
            channel.disconnect();

            log.info("opening sudo connection");
            channel = (ChannelExec)bootstrapSession.openChannel("exec");


            log.info("sudo command: " + sudoCommand);

            log.info("setting sudo command");
            channel.setCommand("sudo " + sudoCommand);
            channel.setPty(true);

            in = channel.getInputStream();
            out = channel.getOutputStream();
            channel.setErrStream(System.err);

            log.info("connecting sudo channel");
            channel.connect();

            while (true)
            {
                while (in.available() > 0)
                {
                    int i = in.read(buf, 0, 1024);
                    if (i < 0)
                    {
                        break;
                    }
                    System.out.print(new String(buf, 0, i));
                }

                if (channel.isClosed())
                {
                    log.info("exit-status: " + channel.getExitStatus());
                    break;
                }
                try
                {
                    Thread.sleep(1000);
                }
                catch (Throwable t)
                {
                }
            }

            log.info("closing sudo connection");
            channel.disconnect();
            bootstrapSession.disconnect();
        }
        catch (IOException | JSchException e)
        {
            log.error(e.getMessage(), e);
            throw new RuntimeException(e);
        }
*/
    }

    private int checkAck(InputStream in) throws IOException
    {
        int b = in.read();
         // b may be 0 for success,
         // 1 for error,
         // 2 for fatal error,
         // -1
        if (b == 0 || b == -1)
        {
            return b;
        }

        if (b == 1 || b == 2)
        {
            StringBuilder strbuf = new StringBuilder();
            int c;
            do
            {
                c =in.read();
                strbuf.append((char)c);
            }
            while(c != '\n');

            if(b == 1) // error
            {
                log.error(strbuf.toString());
            }

            if(b == 2) // fatal error
            {
                log.error(strbuf.toString());
            }
        }

        return b;
    }

}

