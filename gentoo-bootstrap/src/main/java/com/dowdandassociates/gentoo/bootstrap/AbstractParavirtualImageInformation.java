
package com.dowdandassociates.gentoo.bootstrap;

import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractParavirtualImageInformation implements ImageInformation
{
    private static Logger log = LoggerFactory.getLogger(AbstractParavirtualImageInformation.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Image.architecture")
    private Supplier<String> architecture = Suppliers.ofInstance("x86_64");

    @Configuration("com.dowdandassociates.gentoo.bootstrap.Image.bootPartition")
    private Supplier<String> bootPartition = Suppliers.ofInstance("hd0");

    @Override
    public String getArchitecture()
    {
        return architecture.get();
    }

    @Override
    public String getVirtualizationType()
    {
        return "paravirtual";
    }

    @Override
    public String getBootPartition()
    {
        return bootPartition.get();
    }
}

