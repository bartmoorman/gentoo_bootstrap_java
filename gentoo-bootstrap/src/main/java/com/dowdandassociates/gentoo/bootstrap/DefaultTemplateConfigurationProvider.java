
package com.dowdandassociates.gentoo.bootstrap;

import com.google.common.base.Suppliers;
import com.google.common.base.Supplier;

import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

import freemarker.template.DefaultObjectWrapper;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultTemplateConfigurationProvider implements Provider<freemarker.template.Configuration>
{
    private static Logger log = LoggerFactory.getLogger(DefaultTemplateConfigurationProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Template.base")
    private Supplier<String> base = Suppliers.ofInstance("");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Template.localized")
    private Supplier<Boolean> localized = Suppliers.ofInstance(Boolean.FALSE);

    public freemarker.template.Configuration get()
    {
        log.info("com.dowdandassociates.gentoo.bootstrap.Template.base = " + base.get());

        freemarker.template.Configuration cfg = new freemarker.template.Configuration();
        cfg.setTemplateLoader(new SimpleURLTemplateLoader(base.get()));
        cfg.setObjectWrapper(new DefaultObjectWrapper());
        cfg.setLocalizedLookup(localized.get());
        return cfg;
    }
}

