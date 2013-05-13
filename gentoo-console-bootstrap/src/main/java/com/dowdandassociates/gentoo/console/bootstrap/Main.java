/*
 *
 * Main.java
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

package com.dowdandassociates.gentoo.console.bootstrap;

import java.util.Properties;

import com.google.inject.Guice;
import com.google.inject.Injector;

import com.netflix.blitz4j.LoggingConfiguration;
import com.netflix.governator.guice.LifecycleInjector;
import com.netflix.governator.lifecycle.LifecycleManager;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.dowdandassociates.gentoo.bootstrap.GentooBootstrapModule;
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
//            Injector injector = Guice.createInjector(new Amd64MinimalBootstrapModule());
        
            Injector injector = LifecycleInjector.builder().withBootstrapModule(new GentooBootstrapModule()).createInjector();

            LifecycleManager manager = injector.getInstance(LifecycleManager.class);

            manager.start();

            Bootstrapper bootstrapper = injector.getInstance(Bootstrapper.class);

            bootstrapper.execute();

            manager.close();
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

