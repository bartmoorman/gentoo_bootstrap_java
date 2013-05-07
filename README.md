
## Checkout

git clone https://bitbucket.org/edowd/gentoo_bootstrap_java.git
cd gentoo_bootstrap_java

## Build

mvn clean package

## Run

```
java \
-Darchaius.configurationSource.additionalUrls=file://$PWD/config/gentoo-bootstrap_us-east-1.properties \
-Dlog4j.configuration=file://$PWD/config/log4j-info-console.properties \
-jar gentoo-console-bootstrap/target/gentoo-console-bootstrap.one-jar.jar
```

## Run with pre-running instance

```
java \
-Dcom.dowdandassociates.gentoo.bootstrap.BootstrapInstance.instanceId=i-5bd4ff34 \
-Darchaius.configurationSource.additionalUrls=file://$PWD/config/development.properties \
-Dlog4j.configuration=file://$PWD/config/log4j-info-console.properties \
-jar gentoo-console-bootstrap/target/gentoo-console-bootstrap.one-jar.jar
```

## For testing

```
java \
-Darchaius.configurationSource.additionalUrls=file://$PWD/config/development.properties \
-Dlog4j.configuration=file://$PWD/config/log4j-info-console.properties \
-jar gentoo-console-bootstrap/target/gentoo-console-bootstrap.one-jar.jar
```
