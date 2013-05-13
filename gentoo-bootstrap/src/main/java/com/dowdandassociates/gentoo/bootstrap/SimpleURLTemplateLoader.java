/*
 *
 * SimpleURLTemplateLoader.java
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

import java.net.MalformedURLException;
import java.net.URL;

import freemarker.cache.URLTemplateLoader;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SimpleURLTemplateLoader extends URLTemplateLoader
{
    private Logger log = LoggerFactory.getLogger(SimpleURLTemplateLoader.class);

    private String base;

    public SimpleURLTemplateLoader(String base)
    {
        this.base = base;
    }

    protected URL getURL(String name)
    {
        try
        {
            return new URL(base + name);
        }
        catch (MalformedURLException murle)
        {
            return null;
        }
    }
}

