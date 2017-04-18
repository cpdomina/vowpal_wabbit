#!/usr/bin/env bash

# =============================================================================
#  Constants:
# =============================================================================
__not_darwin=1
__brew_not_installed=2

execute="java -cp /vowpal_wabbit/java/target/vw-jni-8.3.3-SNAPSHOT.jar vowpalWabbit.VW;"

ubuntu="
apt-get update -qq;
apt-get install -qq default-jdk;
$execute
"

red_hat="yum update -q -y;
yum install -q -y java-1.7.0-openjdk-devel;
$execute
"

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

run_docker "ubuntu:14.04" "$ubuntu"
run_docker "ubuntu:16.04" "$ubuntu"

#run_docker "centos:6" "$red_hat"
run_docker "centos:7" "$red_hat"

java -cp java/target/vw-jni-8.3.3-SNAPSHOT.jar vowpalWabbit.VW
