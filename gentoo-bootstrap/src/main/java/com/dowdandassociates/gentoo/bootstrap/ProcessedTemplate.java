/*
 *
 * ProcessedTemplate.java
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

package com.dowdandassociates.gentoo.bootstrap;

import java.io.IOException;
//import java.nio.file.DirectoryNotEmptyException;
import java.nio.file.Files;
import java.nio.file.Path;

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

    public void cleanup()
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

