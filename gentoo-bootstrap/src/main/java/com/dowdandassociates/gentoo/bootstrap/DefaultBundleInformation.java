/*
 *
 * DefaultBundleInformation.java
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

import java.io.File;

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;

import com.netflix.governator.annotations.Configuration;
import com.netflix.governator.guice.lazy.FineGrainedLazySingleton;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@FineGrainedLazySingleton
public class DefaultBundleInformation implements BundleInformation
{
    private static Logger log = LoggerFactory.getLogger(DefaultBundleInformation.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Bundle.accountNumber")
    private Supplier<String> accountNumber = Suppliers.ofInstance(null);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Bundle.ec2PrivateKey.remote")
    private Supplier<String> remoteEc2PrivateKey = Suppliers.ofInstance("/tmp/pk.pem");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Bundle.ec2PrivateKey.local")
    private Supplier<String> localEc2PrivateKey = Suppliers.ofInstance(null);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Bundle.ec2Cert.remote")
    private Supplier<String> remoteEc2Cert = Suppliers.ofInstance("/tmp/cert.pem");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Bundle.ec2Cert.local")
    private Supplier<String> localEc2Cert = Suppliers.ofInstance(null);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Bundle.accessKeyId")
    private Supplier<String> accessKeyId = Suppliers.ofInstance(null);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Bundle.secretAccessKey")
    private Supplier<String> secretAccessKey = Suppliers.ofInstance(null);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Bundle.bucket")
    private Supplier<String> bucket = Suppliers.ofInstance(null);

    @Override
    public String getAccountNumber()
    {
        return accountNumber.get();
    }

    @Override
    public String getRemoteEc2PrivateKey()
    {
        return remoteEc2PrivateKey.get();
    }

    @Override
    public String getLocalEc2PrivateKey()
    {
        String filename = localEc2PrivateKey.get();

        if (filename.startsWith("~" + File.separator))
        {
            filename = System.getProperty("user.home") + filename.substring(1);
        }

        return filename;
    }

    @Override
    public String getRemoteEc2Cert()
    {
        return remoteEc2Cert.get();
    }

    @Override
    public String getLocalEc2Cert()
    {
        String filename = localEc2Cert.get();

        if (filename.startsWith("~" + File.separator))
        {
            filename = System.getProperty("user.home") + filename.substring(1);
        }

        return filename;
    }

    @Override
    public String getAccessKeyId()
    {
        return accessKeyId.get();
    }

    @Override
    public String getSecretAccessKey()
    {
        return secretAccessKey.get();
    }

    @Override
    public String getBucket()
    {
        return bucket.get();
    }
}

