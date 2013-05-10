#!/bin/bash

SAMPLE="sample"

echo "hello, world"

<#include "testdir/test2.ftl">

echo "architecture: ${architecture}"

<#noparse>
echo "${SAMPLE}"
</#noparse>

echo "<#noparse>${SAMPLE}</#noparse>"

