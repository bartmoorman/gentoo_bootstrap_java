/*
 *
 * DefaultTemplateProvider.java
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

