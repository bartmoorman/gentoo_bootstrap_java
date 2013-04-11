
## Checkout

git clone https://bitbucket.org/edowd/gentoo_bootstrap_java.git
cd gentoo_bootstrap_java

## Build

mvn clean package

## Run

```
java \
-Darchaius.configurationSource.additionalUrls=https://gist.github.com/ericdowd/5367996/raw/1fdd239081bc236144e45518f25af2a8c25f14d7/gentoo-bootstrap_us-west-2.properties \
-Dlog4j.configuration=https://gist.github.com/ericdowd/5368010/raw/f9eb0fb282623b6083a50c44983734c890f75150/log4j-info-console.properties \
-jar gentoo-console-bootstrap/target/gentoo-console-bootstrap.one-jar.jar
```

