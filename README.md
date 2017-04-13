Simpler, shareable, Vowpal Wabbit jar.


```
brew install libtool autoconf automake boost
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_111.jdk/Contents/Home

sh java/src/main/bin/build.sh

cd java
mvn package

cd target
java -cp vw-jni-8.3.3-SNAPSHOT.jar vowpalWabbit.VW
```
