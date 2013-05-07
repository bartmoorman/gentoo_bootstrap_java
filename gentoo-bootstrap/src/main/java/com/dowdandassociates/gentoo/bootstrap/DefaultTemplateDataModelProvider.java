
package com.dowdandassociates.gentoo.bootstrap;

import java.util.HashMap;
import java.util.Map;

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;
import com.google.inject.name.Named;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultTemplateDataModelProvider implements Provider<Object>
{
    private static Logger log = LoggerFactory.getLogger(DefaultTemplateDataModelProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.mirror")
    private Supplier<String> mirror = Suppliers.ofInstance("http://gentoo.mirrors.pair.com/");

    private Supplier<String> architecture;

    @Inject
    private void setArchitecture(@Named("Architecture") Supplier<String> architecture)
    {
        this.architecture = architecture;
    }

    public Object get()
    {
        Map root = new HashMap();

        root.put("architecture", architecture.get());
        root.put("mirror", mirror.get());

        return root;
    }
}

