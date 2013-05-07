
package com.dowdandassociates.gentoo.bootstrap;

import java.io.IOException;

import com.google.common.base.Optional;
import com.google.common.base.Suppliers;
import com.google.common.base.Supplier;

import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

import freemarker.template.DefaultObjectWrapper;
import freemarker.template.Template;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultTemplateProvider implements Provider<Optional<Template>>
{
    private static Logger log = LoggerFactory.getLogger(DefaultTemplateProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Template.base")
    private Supplier<String> base = Suppliers.ofInstance("");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Template.localized")
    private Supplier<Boolean> localized = Suppliers.ofInstance(Boolean.FALSE);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Template.path")
    private Supplier<String> path = Suppliers.ofInstance("");

    public Optional<Template> get()
    {
        log.info("com.dowdandassociates.gentoo.bootstrap.Template.base = " + base.get());
        log.info("com.dowdandassociates.gentoo.bootstrap.Template.path = " + path.get());

        try
        {
            freemarker.template.Configuration cfg = new freemarker.template.Configuration();
            cfg.setTemplateLoader(new SimpleURLTemplateLoader(base.get()));
            cfg.setObjectWrapper(new DefaultObjectWrapper());
            cfg.setLocalizedLookup(localized.get());
            return Optional.fromNullable(cfg.getTemplate(path.get()));
        }
        catch (IOException e)
        {
            log.error(e.getMessage(), e);
            return Optional.absent();
        }
    }
}

