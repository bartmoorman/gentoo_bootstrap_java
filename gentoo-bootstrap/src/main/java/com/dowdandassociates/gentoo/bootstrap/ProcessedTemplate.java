
package com.dowdandassociates.gentoo.bootstrap;

import java.io.IOException;
//import java.nio.file.DirectoryNotEmptyException;
import java.nio.file.Files;
import java.nio.file.Path;

import javax.annotation.PreDestroy;

import com.google.common.base.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ProcessedTemplate
{
    private static Logger log = LoggerFactory.getLogger(ProcessedTemplate.class);

    private boolean temporaryFile;
    private Optional<Path> path;

    public ProcessedTemplate()
    {
    }

    public boolean isTempoaryFile()
    {
        return temporaryFile;
    }

    public void setTemporaryFile(boolean temporaryFile)
    {
        this.temporaryFile = temporaryFile;
    }

    public ProcessedTemplate withTemporaryFile(boolean temporaryFile)
    {
        setTemporaryFile(temporaryFile);
        return this;
    }

    public Optional<Path> getPath()
    {
        return path;
    }

    public void setPath(Optional<Path> path)
    {
        if (null == path)
        {
            this.path = Optional.absent();
        }
        else
        {
            this.path = path;
        }
    }

    public void setPath(Path path)
    {
        this.path = Optional.fromNullable(path);
    }

    public ProcessedTemplate withPath(Optional<Path> path)
    {
        setPath(path);
        return this;
    }

    public ProcessedTemplate withPath(Path path)
    {
        setPath(path);
        return this;
    }

    @PreDestroy
    private void tearDown()
    {
        if (temporaryFile && path.isPresent())
        {
            try
            {
                log.info("Deleting " + path.get());
                Files.deleteIfExists(path.get());
            }
            catch (IOException |
                    SecurityException e)
            {
                log.info("Could not delete temporary processed template");
            }
        }
    }
}

