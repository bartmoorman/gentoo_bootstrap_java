
# Gentoo Bootstrap Java

This is a Java reimplementation of the the [Gentoo Bootstrap](https://bitbucket.org/edowd/gentoo_bootstrap) bash scripts. The purpose is to allow for more flexibility with options, to more easily make your own script to run on the server side, and to eliminate the need for the [ec2-api-tools](http://aws.amazon.com/developertools/351).

## Checkout

git clone https://bitbucket.org/edowd/gentoo_bootstrap_java.git
cd gentoo_bootstrap_java

## Build

mvn clean package

## Run

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

### HVM test

```
java \
-Darchaius.configurationSource.additionalUrls=https://bitbucket.org/edowd/gentoo_bootstrap_java/raw/hvm-test/config/Gentoo_HVM-test_us-east-1.properties \
-Dlog4j.configuration=https://bitbucket.org/edowd/gentoo_bootstrap_java/raw/master/config/log4j-info-console.properties \
-jar gentoo-console-bootstrap/target/gentoo-console-bootstrap.one-jar.jar
```

###### Gentoo is a trademark of Gentoo Foundation, Inc. Gentoo Bootstrap is not part of the Gentoo Project and is not directed or managed by Gentoo Foundation, Inc.

