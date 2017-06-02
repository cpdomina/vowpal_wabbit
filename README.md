Modifications to Vowpal Wabbit in order to create a simpler, shareable, Vowpal Wabbit jar.


## Create Jar

```
brew install libtool autoconf automake boost
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_111.jdk/Contents/Home

# Create system libraries with static dependencies that will work on MacOSx and most 64-bit Linux distros
sh java/src/main/bin/build.sh

# Create jar that will load system library depending on the OS
cd java
mvn package

# Test if Jar works
cd target
java -cp vw-jni-8.3.3-SNAPSHOT.jar vowpalWabbit.VW
```


## Create Machine-dependent System Library
```
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_111.jdk/Contents/Home

# Ubuntu
apt-get install software-properties-common g++ make libboost-program-options-dev zlib1g-dev

# Red-Hat
yum install gcc-c++ make boost-devel zlib-devel perl clang redhat-lsb-core

# Mac OS X
brew install libtool autoconf automake boost

# Creates and installs system library for the current machine, that will be accessible system-wide (including by the previously created Jar)
make clean java
sudo make java_install
```
