
package com.dowdandassociates.gentoo.bootstrap;

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultScriptNameProvider implements Provider<Supplier<String>>
{
    private static Logger log = LoggerFactory.getLogger(DefaultScriptNameProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Script.name")
    private Supplier<String> scriptName = Suppliers.ofInstance("bootstrap.sh");

    public Supplier<String> get()
    {
        return scriptName;
    }
}

