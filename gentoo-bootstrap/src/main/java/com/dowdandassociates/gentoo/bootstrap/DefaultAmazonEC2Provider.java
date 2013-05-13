/*
 *
 * DefaultAmazonEC2Provider.java
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

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.AmazonEC2Client;

import com.google.common.base.Suppliers;
import com.google.common.base.Supplier;

import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

public class DefaultAmazonEC2Provider implements Provider<AmazonEC2>
{
    @Configuration("com.amazonaws.services.ec2.AmazonEC2.endpoint")
    private Supplier<String> endpoint = Suppliers.ofInstance("https://ec2.us-east-1.amazonaws.com");

    public DefaultAmazonEC2Provider()
    {
    }

    public AmazonEC2 get()
    {
        AmazonEC2 ec2Client = new AmazonEC2Client();
        ec2Client.setEndpoint(endpoint.get());
        return ec2Client;
    }
}

