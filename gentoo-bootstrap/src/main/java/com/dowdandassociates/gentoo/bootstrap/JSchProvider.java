
package com.dowdandassociates.gentoo.bootstrap;

import com.google.common.base.Optional;

import com.google.inject.Inject;
import com.google.inject.Provider;

import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class JSchProvider implements Provider<Optional<JSch>>
{
    private static Logger log = LoggerFactory.getLogger(JSchProvider.class);

    private KeyPairInformation keyPair;

    @Inject
    public JSchProvider(KeyPairInformation keyPair)
    {
        this.keyPair = keyPair;
    }

    public Optional<JSch> get()
    {
        log.info("Get JSch");
        try
        {
            JSch jsch = new JSch();

            jsch.addIdentity(keyPair.getFilename());

            return Optional.of(jsch);
        }
        catch (JSchException jse)
        {
            log.error(jse.getMessage(), jse);
            return Optional.absent();
        }
    }
}

