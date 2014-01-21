
# Gentoo Bootstrap Java

This is a Java reimplementation of the the [Gentoo Bootstrap](https://bitbucket.org/edowd/gentoo_bootstrap) bash scripts. The purpose is to allow for more flexibility with options, to more easily make your own script to run on the server side, and to eliminate the need for the [ec2-api-tools](http://aws.amazon.com/developertools/351).

## Checkout

```
git clone https://bitbucket.org/edowd/gentoo_bootstrap_java.git
cd gentoo_bootstrap_java
```

## Build

```
mvn clean package
```

## Pygoscelis Papua

The successor to the Gentoo in the Cloud images is Pygoscelis Papua images:

### 64-bit EBS us-east-1

```
java \
-Darchaius.configurationSource.additionalUrls=https://bitbucket.org/edowd/gentoo_bootstrap_java/raw/master/config/Pygoscelis-Papua-64-bit-EBS_us-east-1.properties \
-Dlog4j.configuration=https://bitbucket.org/edowd/gentoo_bootstrap_java/raw/master/config/log4j-info-console.properties \
-jar gentoo-console-bootstrap/target/gentoo-console-bootstrap.one-jar.jar
```

### 32-bit EBS us-east-1

```
java \
-Darchaius.configurationSource.additionalUrls=https://bitbucket.org/edowd/gentoo_bootstrap_java/raw/master/config/Pygoscelis-Papua-32-bit-EBS_us-east-1.properties \
-Dlog4j.configuration=https://bitbucket.org/edowd/gentoo_bootstrap_java/raw/master/config/log4j-info-console.properties \
-jar gentoo-console-bootstrap/target/gentoo-console-bootstrap.one-jar.jar
```

### HVM us-east-1

Due to difficulties in getting the aws java sdk and one-jar to play nicely together, we currently have a shell script for converting the 64-bit EBS image to HVM. It requires the [aws cli tool](http://www.dowdandassociates.com/blog/content/howto-install-aws-cli-aws-command-line-interface/) and [jq](http://www.dowdandassociates.com/blog/content/howto-install-jq/)

```
cd hvm
./paravirtual2hvm <64-bit-ebs-image-id>
```

so for example

```
cd hvm
./paravirtual2hvm ami-19ad9f70
```

## Gentoo in the Cloud

To build the older gentoo in the cloud images:

### 64-bit EBS us-east-1

```
java \
-Darchaius.configurationSource.additionalUrls=https://bitbucket.org/edowd/gentoo_bootstrap_java/raw/master/config/Gentoo_64-bit-EBS_us-east-1.properties \
-Dlog4j.configuration=https://bitbucket.org/edowd/gentoo_bootstrap_java/raw/master/config/log4j-info-console.properties \
-jar gentoo-console-bootstrap/target/gentoo-console-bootstrap.one-jar.jar
```

### 32-bit EBS us-east-1

```
java \
-Darchaius.configurationSource.additionalUrls=https://bitbucket.org/edowd/gentoo_bootstrap_java/raw/master/config/Gentoo_32-bit-EBS_us-east-1.properties \
-Dlog4j.configuration=https://bitbucket.org/edowd/gentoo_bootstrap_java/raw/master/config/log4j-info-console.properties \
-jar gentoo-console-bootstrap/target/gentoo-console-bootstrap.one-jar.jar
```

###### Gentoo is a trademark of Gentoo Foundation, Inc. Gentoo Bootstrap is not part of the Gentoo Project and is not directed or managed by Gentoo Foundation, Inc.

