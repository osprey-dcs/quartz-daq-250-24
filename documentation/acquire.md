# Acquisition Engine and Previewer App.

These software packages coordinate a set of Quartz chassis to acquire synchronously
stream data to disk,
previewer acquired data,
and to export some/all to as [UFF58b](https://en.wikipedia.org/wiki/Universal_File_Format) files.

## Prerequisites

- At least 1 running [Quartz IOC](ioc-setup.md).
- Assumes IOC record named or aliased as `<prefix>:##:` where `##` is a two digit decimal number in the range 1 through the number of running IOCs.


## Preparation

- The [P4P](https://github.com/epics-base/p4p) python module may be build and install as either an EPICS module (shown below), or as a [python package](https://pypi.org/project/p4p/) if eg. a python virtualenv is preferred.

Assumes previous completion of Preparation section of [IOC setup](ioc-setup.md).

```
sudo apt-get update
sudo apt-get install -y python3-inotify build-essential pkg-config \
  python3-dev python3-numpy-dev python3-setuptools python3-cython \
  cmake libqt5charts5-dev libfftw3-dev

git clone https://github.com/epics-base/p4p
git clone https://github.com/osprey-dcs/quartz-config-loader
git clone https://github.com/osprey-dcs/atf-engine
git clone https://github.com/osprey-dcs/atf-previewer
git clone https://github.com/osprey-dcs/quartz-scripts

cat <<EOF > p4p/configure/RELEASE.local
PVXS=\$(TOP)/../pvxs
EPICS_BASE=\$(TOP)/../epics-base
EOF

make -C p4p

(cd atf-engine && ./setup.py build_ext -i)

cmake -S atf-previewer -B atf-previewer/build
cmake --build atf-previewer/build/

```

## atf-engine

Choose a directory to start acquired data files.
In this example: `/data`.

An example systemd `atf-engine/atf-engine.service` is provided,
which will need to be adapted to the target installation,
based on choice of user account, python install mechanism, and paths.

In the following `/path/to/p4p/python3.13/linux-x86_64` may need to be adjusted,
also `--root /data`.

```systemd
Environment="PYTHONPATH=/path/to/p4p/python3.13/linux-x86_64"

ExecStart=/usr/local/epics/usr/bin/procServ \
  --foreground --logfile - --name atf-engine \
  --ignore ^D^C^] --logoutcmd ^D \
  --chdir /opt/atf-engine \
  --info-file %t/atf-engine/info \
  -P unix:%t/atf-engine/control \
  -P 10100 \
  python3 -m atf_engine \
  --root /data
```

## atf-previewer

```sh
./atf-previewer/build/viewer
```
