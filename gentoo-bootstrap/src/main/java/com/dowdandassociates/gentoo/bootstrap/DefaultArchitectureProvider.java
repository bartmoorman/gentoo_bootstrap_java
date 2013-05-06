
package com.dowdandassociates.gentoo.bootstrap;

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultArchitectureProvider implements Provider<String>
{
    private static Logger log = LoggerFactory.getLogger(DefaultArchitectureProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.architecture")
    private Supplier<String> architecture = Suppliers.ofInstance("x86_64");

    public String get()
    {
        return architecture.get();
    }
}

