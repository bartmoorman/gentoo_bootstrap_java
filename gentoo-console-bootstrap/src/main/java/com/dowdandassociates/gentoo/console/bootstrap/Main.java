
package com.dowdandassociates.gentoo.console.bootstrap;

import com.google.inject.Guice;
import com.google.inject.Injector;

import com.netflix.blitz4j.LoggingConfiguration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.dowdandassociates.gentoo.bootstrap.Amd64MinimalBootstrapModule;
import com.dowdandassociates.gentoo.bootstrap.Bootstrapper;

public class Main
{
    private static Logger log = LoggerFactory.getLogger(Main.class);

    public static void main(String[] args)
    {
        LoggingConfiguration.getInstance().configure();

        try
        {
            Injector injector = Guice.createInjector(new Amd64MinimalBootstrapModule());
        
            Bootstrapper bootstrapper = injector.getInstance(Bootstrapper.class);

            bootstrapper.execute();
        }
        catch (Throwable t)
        {
            log.error(t.getMessage(), t);
        }
        finally
        {
            LoggingConfiguration.getInstance().stop();
        }
    }
}

