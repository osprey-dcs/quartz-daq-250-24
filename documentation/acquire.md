# Acquisition Engine and Previewer App.

These software packages coordinate a set of Quartz chassis to acquire synchronously
stream data to disk,
previewer acquired data,
and to export some/all to as [UFF58b](https://en.wikipedia.org/wiki/Universal_File_Format) files.

The following packages are involved.

- atf-engine, Coordinates acquisition process, collecting channel meta-data, and post-acquisition processing.
- atf-previewer, GUI for viewing recorded data.  Exports some/all to UFF58b files.
- quartz-scripts, python API for manipulating either raw or UFF58b data files.
- quartz-config-loader, Read Quartz channel configuration in bulk from a CSV file.  (Optional)

## Prerequisites

- At least 1 running [Quartz IOC](ioc-setup.md).
- Assumes IOC record named or aliased as `<prefix>:##:` where `##` is a two digit decimal number in the range 1 through the number of running IOCs.

## Pre-Preparation

On a host which is able to reach https://pypi.org ,
running the same Linux distribution version as the final/target host.

If the target host is able to reach pypi.org,
then skip this section and omit `--no-index -f ./wheels`
in the following section.

```sh
sudo apt-get update
sudo apt-get install -y python3-virtualenv

virtualenv ./env
./env/bin/pip download -d ./wheels p4p 'inotify~=0.2'
```

Copy the directory `wheels/` to the target host.

## Preparation

- The [P4P](https://github.com/epics-base/p4p) python module may be build and install as either an EPICS module (shown below), or as a [python package](https://pypi.org/project/p4p/) if eg. a python virtualenv is preferred.

Assumes previous completion of Preparation section of [IOC setup](ioc-setup.md).

The absolute path to the `./env/` directory will be needed in the following section.

```
sudo apt-get update
sudo apt-get install -y build-essential pkg-config \
  python3-virtualenv python3-scipy \
  cmake libqt5charts5-dev libfftw3-dev

virtualenv ./env
./env/bin/pip install --no-index -f ./wheels p4p 'inotify~=0.2'

git clone https://github.com/osprey-dcs/quartz-config-loader
git clone https://github.com/osprey-dcs/atf-engine
git clone https://github.com/osprey-dcs/atf-previewer
git clone https://github.com/osprey-dcs/quartz-scripts

(cd atf-engine && ../env/bin/python setup.py build_ext -i)

cmake -S atf-previewer -B atf-previewer/build
cmake --build atf-previewer/build/

```

## atf-engine

Choose a directory to start acquired data files.
In this example: `/data`.

An example systemd `atf-engine/atf-engine.service` is provided,
which will need to be adapted to the target installation,
based on choice of user account, python install mechanism, and paths.

In the following `/path/to/env/bin/python` may need to be adjusted,
also `--root /data`.

```systemd
ExecStart=/usr/local/epics/usr/bin/procServ \
  --foreground --logfile - --name atf-engine \
  --ignore ^D^C^] --logoutcmd ^D \
  --chdir /opt/atf-engine \
  --info-file %t/atf-engine/info \
  -P unix:%t/atf-engine/control \
  -P 10100 \
  /path/to/env/bin/python -m atf_engine \
  --prefix FDAS: \
  --root /data
```

## atf-previewer

```sh
./atf-previewer/build/viewer
```

## quartz-config-loader

An example systemd `quartz-config-loader/quartz-config-loader.service` is provided.
In the following `/path/to/env/bin/python` may need to be adjusted,
also `--prefix MDAS:`.

```systemd
[Service]
ExecStart=/usr/local/epics/usr/bin/procServ \
  --foreground --logfile - --name cccr \
  --chdir /opt/quartz-config-loader \
  --info-file %t/%n/info \
  --port 0 \
  --port unix:%t/%n/control \
  /path/to/env/bin/python -m cccr_configurer.server \
    --prefix MDAS:
```
