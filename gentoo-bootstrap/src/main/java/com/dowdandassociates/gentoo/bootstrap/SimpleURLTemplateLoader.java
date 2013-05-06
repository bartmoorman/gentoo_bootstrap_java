
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

