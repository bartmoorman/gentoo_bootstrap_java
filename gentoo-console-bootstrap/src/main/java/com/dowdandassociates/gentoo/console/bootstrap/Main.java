
package com.dowdandassociates.gentoo.console.bootstrap;

import java.util.Properties;

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
/*
        Properties props = new Properties();
        props.setProperty("log4j.rootCategory", "DEBUG,stdout");
        props.setProperty("log4j.appender.stdout", "org.apache.log4j.ConsoleAppender");
        props.setProperty("log4j.appender.stdout.layout", "com.netflix.logging.log4jAdapter.NFPatternLayout");
        props.setProperty("log4j.appender.stdout.layout.ConversionPattern", "%d %-5p %C:%L [%t] [%M] %m%n");
        props.setProperty("log4j.logger.asyncAppenders", "DEBUG,stdout");
        LoggingConfiguration.getInstance().configure(props);
*/
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

