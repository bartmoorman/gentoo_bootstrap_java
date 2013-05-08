
package com.dowdandassociates.gentoo.bootstrap;

public interface BundleInformation
{
    public String getAccountNumber();
    public String getRemoteEc2PrivateKey();
    public String getLocalEc2PrivateKey();
    public String getRemoteEc2Cert();
    public String getLocalEc2Cert();
    public String getAccessKeyId();
    public String getSecretAccessKey();
    public String getBucket();
}

