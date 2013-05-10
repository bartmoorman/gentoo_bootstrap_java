<#if architecture == "i386">
<#include ".config-i386.ftl" parse=false>
<#else>
<#include ".config-x86_64.ftl" parse=false>
</#if>
