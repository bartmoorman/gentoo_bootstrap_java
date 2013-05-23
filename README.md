
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

