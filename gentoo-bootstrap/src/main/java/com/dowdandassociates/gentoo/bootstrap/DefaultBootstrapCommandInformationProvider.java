/*
 *
 * DefaultBootstrapCommandInformationProvider.java
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

import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;
import com.google.inject.name.Named;

import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultBootstrapCommandInformationProvider implements Provider<BootstrapCommandInformation>
{
    private static Logger log = LoggerFactory.getLogger(DefaultBootstrapCommandInformationProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Script.directory")
    private Supplier<String> directory = Suppliers.ofInstance("/tmp");

    private BootstrapSessionInformation sessionInfo;
    private ProcessedTemplate processedTemplate;
    private Supplier<String> scriptName;

    @Inject
    public DefaultBootstrapCommandInformationProvider(
            BootstrapSessionInformation sessionInfo,
            ProcessedTemplate processedTemplate,
            @Named("Script Name") Supplier<String> scriptName)
    {
        this.sessionInfo = sessionInfo;
        this.processedTemplate = processedTemplate;
        this.scriptName = scriptName;
    }

    public BootstrapCommandInformation get()
    {
        if (!sessionInfo.getSession().isPresent() || !processedTemplate.getPath().isPresent())
        {
            processedTemplate.cleanup();
            Optional<String> command = Optional.absent();
            return new BootstrapCommandInformation().
                    withSessionInfo(sessionInfo).
                    withCommand(command);
        }

        try
        {
            Session session = sessionInfo.getSession().get();
            Path path = processedTemplate.getPath().get();
            String filename = directory.get() + "/" + scriptName.get();

            log.info("Openning channel");

            ChannelExec channel = (ChannelExec)session.openChannel("exec");

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
            command.append((Long)Files.getAttribute(path, "basic:size"));
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
            InputStream is = Files.newInputStream(path);
            byte[] buf = new byte[1024];
            while (true)
            {
                int len = is.read(buf, 0, buf.length);
                if (len <= 0)
                {
                    break;
                }
                out.write(buf, 0, len);
            }
            is.close();
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

            return new BootstrapCommandInformation().
                    withSessionInfo(sessionInfo).
                    withCommand(filename);
        }
        catch (IllegalArgumentException |
                IOException |
                JSchException |
                SecurityException |
                UnsupportedOperationException e)
        {
            log.error(e.getMessage(), e);
            Optional<String> command = Optional.absent();
            return new BootstrapCommandInformation().
                    withSessionInfo(sessionInfo).
                    withCommand(command);
        }
        finally
        {
            processedTemplate.cleanup();
        }
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

