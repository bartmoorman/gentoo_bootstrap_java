
package com.dowdandassociates.gentoo.bootstrap;

import com.google.common.base.Suppliers;
import com.google.common.base.Supplier;

import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultTemplateProvider implements Provider<String>
{
    private static Logger log = LoggerFactory.getLogger(DefaultTemplateProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Template.path")
    private Supplier<String> path = Suppliers.ofInstance("");

    public String get()
    {
        log.info("com.dowdandassociates.gentoo.bootstrap.Template.path = " + path.get());
        return path.get();
    }
}

