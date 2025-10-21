# Notes for RHEL derivatives

Tested on rockylinux 9.5

## Marble MMC USB

```sh
sudo dnf install python3-pyserial
```

## Quartz IOC dependencies

```sh
sudo dnf install \
  gcc-c++ glibc-devel make readline-devel ncurses-devel autoconf automake \
  perl-devel pkg-config pcre-devel
```

## Build cs-studio/phoebus

```sh
sudo dnf install git java-21-openjdk-devel maven-openjdk21

git clone --depth 1 https://github.com/ControlSystemStudio/phoebus

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk

mvn clean install -Dmaven.test.skip=true
```
