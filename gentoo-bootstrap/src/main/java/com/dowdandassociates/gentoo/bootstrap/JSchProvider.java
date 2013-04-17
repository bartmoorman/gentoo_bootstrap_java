
package com.dowdandassociates.gentoo.bootstrap;

import com.google.inject.Inject;
import com.google.inject.Provider;

import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class JSchProvider implements Provider<JSch>
{
    private static Logger log = LoggerFactory.getLogger(JSchProvider.class);

    private KeyPairInformation keyPair;

    @Inject
    public JSchProvider(KeyPairInformation keyPair)
    {
        this.keyPair = keyPair;
    }

    public JSch get()
    {
        try
        {
            JSch jsch = new JSch();

            jsch.addIdentity(keyPair.getFilename());

            return jsch;
        }
        catch (JSchException jse)
        {
            log.error(jse.getMessage(), jse);
            return null;
        }
    }
}

