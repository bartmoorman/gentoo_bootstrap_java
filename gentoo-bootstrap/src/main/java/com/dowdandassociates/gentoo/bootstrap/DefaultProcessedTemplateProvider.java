
package com.dowdandassociates.gentoo.bootstrap;

import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.nio.file.Files;
import java.nio.file.Path;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;

import com.google.inject.Inject;
import com.google.inject.Provider;
import com.google.inject.name.Named;

import freemarker.template.Template;
import freemarker.template.TemplateException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultProcessedTemplateProvider implements Provider<ProcessedTemplate>
{
    private static Logger log = LoggerFactory.getLogger(DefaultProcessedTemplateProvider.class);

    private Supplier<String> scriptName;
    private Optional<Template> template;
    private Object templateDataModel;

    @Inject
    DefaultProcessedTemplateProvider(
            @Named("Script Name") Supplier<String> scriptName,
            Optional<Template> template,
            @Named("Template Data Model") Object templateDataModel)
    {
        this.scriptName = scriptName;
        this.template = template;
        this.templateDataModel = templateDataModel;
    }

    public ProcessedTemplate get()
    {
        boolean temporaryFile;
        Optional<Path> path;

        if (template.isPresent())
        {
            try
            {
                Path tempFile = Files.createTempFile(scriptName.get(), ".tmp");
                Writer out = new FileWriter(tempFile.toFile());
                template.get().process(templateDataModel, out);
                out.close();
                log.info("Processed template in " + tempFile.toString());
                temporaryFile = true;
                path = Optional.of(tempFile);
            }
            catch (IllegalArgumentException |
                    IOException |
                    SecurityException |
                    TemplateException |
                    UnsupportedOperationException e)
            {
                log.error(e.getMessage(), e);
                temporaryFile = false;
                path = Optional.absent();
            }
        }
        else
        {
            log.info("No template");
            temporaryFile = false;
            path = Optional.absent();
        }

        return new ProcessedTemplate().
                withTemporaryFile(temporaryFile).
                withPath(path);
    }
}

