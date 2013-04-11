
package com.dowdandassociates.gentoo.console.bootstrap;

import com.google.inject.Guice;
import com.google.inject.Injector;

import com.dowdandassociates.gentoo.bootstrap.Amd64MinimalBootstrapModule;
import com.dowdandassociates.gentoo.bootstrap.Bootstrapper;

public class Main
{
    public static void main(String[] args)
    {
        Injector injector = Guice.createInjector(new Amd64MinimalBootstrapModule());
        
        Bootstrapper bootstrapper = injector.getInstance(Bootstrapper.class);

        bootstrapper.execute();
    }
}

