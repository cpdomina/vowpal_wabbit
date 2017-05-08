#!/usr/bin/env bash

# =============================================================================
#  Constants:
# =============================================================================
__not_darwin=1
__brew_not_installed=2

make_base="
wget https://sourceforge.net/projects/boost/files/boost/1.61.0/boost_1_61_0.tar.gz;
tar -xzf boost_1_61_0.tar.gz
cd boost_1_61_0;
./bootstrap.sh;
./bjam toolset=gcc cxxflags=-fPIC cflags=-fPIC -a link=static --with-program_options install;

wget http://zlib.net/zlib-1.2.11.tar.gz;
tar -xzf zlib-1.2.11.tar.gz;
cd zlib-1.2.11;
CFLAGS='-fPIC -O3' ./configure;
make install;

cd /vowpal_wabbit;
make clean vw java;"

ubuntu_base="
apt-get update -qq;
apt-get install -qq software-properties-common g++-4.6 make default-jdk wget;
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.6 20;
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.6 20;
update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 30;
update-alternatives --set cc /usr/bin/gcc;
update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 30;
update-alternatives --set c++ /usr/bin/g++;
"

ubuntu_14="$ubuntu_base
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64;
$make_base
mv java/target/libvw_jni.so java/target/vw_jni.linux.amd64.lib"


# =============================================================================
#  Function Definitions:
# =============================================================================

# -----------------------------------------------------------------------------
#  Print red text to stderr.
# -----------------------------------------------------------------------------
red() {
  # https://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/
  echo >&2 "$(tput setaf 1)${1}$(tput sgr0)"
}

# -----------------------------------------------------------------------------
#  Print yellow text to stderr.
# -----------------------------------------------------------------------------
yellow() {
  echo >&2 "$(tput setaf 3)${1}$(tput sgr0)"
}

die() { red $2; exit $1; }

# -----------------------------------------------------------------------------
#  Check that the OS is OS X.  If not, die.  If so, check that brew is
#  installed.  If brew is not installed, ask the user if they want to install.
#  If so, attempt to install.  After attempting install, check for existence.
#  If it still doesn't exist, fail.
# -----------------------------------------------------------------------------
check_brew_installed() {
  local os=$(uname)
  if [[ "$os" != "Darwin" ]]; then
    die $__not_darwin "Build script only supported on OS X.  OS=${os}.  Aborting ..."
  else
    if ! brew help 1>/dev/null 2>/dev/null; then
      red "brew not installed.  To install: Y or N?"
      read should_install
      if [[ "Y" == "${should_install^^}" ]]; then
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
      fi
      if ! brew help 1>/dev/null 2>/dev/null; then
        die $__brew_not_installed "brew not installed.  Aborting ..."
      fi
    fi
  fi
}

install_brew_cask() {
  if ! brew cask 1>/dev/null 2>/dev/null; then
    yellow "Installing brew-cask..."
    brew install caskroom/cask/brew-cask
  fi
}

install_brew_app() {
  local app=$1
  if ! brew list | grep $app 1>/dev/null; then
    yellow "installing brew app: $app"
    brew install $app
  fi
}

install_cask_app() {
  local app=$1
  if ! brew cask list | grep $app 1>/dev/null; then
    yellow "installing brew cask app: $app"
    brew cask install $app
  fi
}

run_docker() {
  local machine=$1
  local script=$2
  docker run --rm -v $(pwd):/vowpal_wabbit $machine /bin/bash -c "$script"
}

# =============================================================================
#  Main
# =============================================================================

check_brew_installed
install_brew_cask
install_cask_app "virtualbox"
install_brew_app "docker-machine"
install_brew_app "docker"

docker-machine create --driver virtualbox default
docker-machine start default
eval "$(docker-machine env default)"

set -e
set -u
set -x

run_docker "ubuntu:14.04" "$ubuntu_14"

make clean
make vw java
mv java/target/libvw_jni.dylib java/target/vw_jni.darwin.x86_64.lib
