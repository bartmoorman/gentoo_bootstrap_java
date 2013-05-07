
package com.dowdandassociates.gentoo.bootstrap;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;

import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultBootstrapResultInformationProvider implements Provider<BootstrapResultInformation>
{
    private static Logger log = LoggerFactory.getLogger(DefaultBootstrapResultInformationProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Script.sudo")
    private Supplier<Boolean> sudo = Suppliers.ofInstance(Boolean.TRUE);

    private BootstrapCommandInformation commandInfo;

    @Inject
    public DefaultBootstrapResultInformationProvider(BootstrapCommandInformation commandInfo)
    {
        this.commandInfo = commandInfo;
    }

    public BootstrapResultInformation get()
    {
        BootstrapSessionInformation sessionInfo = commandInfo.getSessionInfo();
        BootstrapInstanceInformation instanceInfo = sessionInfo.getInstanceInfo();

        if (!commandInfo.getCommand().isPresent() || !sessionInfo.getSession().isPresent())
        {
            Optional<Integer> exitStatus = Optional.absent();
            return new BootstrapResultInformation().
                    withInstance(instanceInfo.getInstance()).
                    withVolume(instanceInfo.getVolume()).
                    withExitStatus(exitStatus);
        }

        try
        {
            log.info("opening connection");
            Session session = sessionInfo.getSession().get();
            ChannelExec channel = (ChannelExec)session.openChannel("exec");

            StringBuilder command = new StringBuilder();
            if (sudo.get())
            {
                command.append("sudo ");
            }
            command.append(commandInfo.getCommand().get());

            log.info("command: " + command.toString());

            log.info("setting command");
            channel.setCommand(command.toString());
            channel.setPty(true);

            InputStream in = channel.getInputStream();
            OutputStream out = channel.getOutputStream();
            channel.setErrStream(System.err);

            log.info("connecting channel");
            channel.connect();

            byte[] buf = new byte[1024];


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

            int exitStatus = channel.getExitStatus();

            log.info("closing connection");
            channel.disconnect();
            session.disconnect();

            return new BootstrapResultInformation().
                    withInstance(instanceInfo.getInstance()).
                    withVolume(instanceInfo.getVolume()).
                    withExitStatus(exitStatus);
        }
        catch (IOException | JSchException e)
        {
            log.error(e.getMessage(), e);
            Optional<Integer> exitStatus = Optional.absent();
            return new BootstrapResultInformation().
                    withInstance(instanceInfo.getInstance()).
                    withVolume(instanceInfo.getVolume()).
                    withExitStatus(exitStatus);
        }
    }
}

