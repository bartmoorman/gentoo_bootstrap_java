/*
 *
 * JSchProvider.java
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

