
## Checkout

git clone https://bitbucket.org/edowd/gentoo_bootstrap_java.git
cd gentoo_bootstrap_java

## Build

mvn clean package

## Run

java -Dlog4j.configuration=https://gist.github.com/ericdowd/5362307/raw/8c6409cdd4a8443b7cc66151a32841387430b494/log4j-debug-console.properties -jar gentoo-console-bootstrap/target/gentoo-console-bootstrap.one-jar.jar

