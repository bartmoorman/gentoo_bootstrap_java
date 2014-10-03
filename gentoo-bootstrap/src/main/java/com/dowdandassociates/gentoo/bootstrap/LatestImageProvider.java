/*
 *
 * LatestImageProvider.java
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

import java.util.HashMap;
import java.util.Map;
import java.util.SortedSet;
import java.util.TreeSet;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeImagesRequest;
import com.amazonaws.services.ec2.model.DescribeImagesResult;
import com.amazonaws.services.ec2.model.Image;

import com.google.common.base.Optional;

import com.google.inject.Provider;

import org.apache.commons.lang3.StringUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class LatestImageProvider implements Provider<Optional<Image>> 
{
    private static Logger log = LoggerFactory.getLogger(LatestImageProvider.class);

    private AmazonEC2 ec2Client;

    public LatestImageProvider(AmazonEC2 ec2Client)
    {
        this.ec2Client = ec2Client;
    }

    @Override
    public Optional<Image> get()
    {
        DescribeImagesResult result = ec2Client.describeImages(getRequest());

        Map<String, Image> imageMap = new HashMap<String, Image>();

        for (Image image : result.getImages())
        {
            String imageLocation = StringUtils.substringAfterLast(image.getImageLocation(), "/");
            if (StringUtils.isBlank(imageLocation))
            {
                imageLocation = image.getImageLocation();
            }
            log.info("imageLocation = " + imageLocation);
            imageMap.put(imageLocation, image);
        }

        if (imageMap.isEmpty())
        {
            return Optional.absent();
        }

        SortedSet<String> sortedKeySet = new TreeSet<String>();
        sortedKeySet.addAll(imageMap.keySet());
        String[] keys = sortedKeySet.toArray(new String[0]);
        log.info("key = " + keys[keys.length - 1]);
        return Optional.fromNullable(imageMap.get(keys[keys.length - 1]));
    }

    protected abstract DescribeImagesRequest getRequest();
}

