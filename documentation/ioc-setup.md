# Quartz EPICS IOC Setup

This document describes setting up and running an EPICS IOC
to communicate with a Quartz ADC chassis

## Prerequisites

1. Working Debian Linux 12 computer with internet access.
2. Quartz-DAQ-250-24 chassis
  - IP address known.
  - This document uses `192.168.79.8` as an example
  - Application firmware image programmed
3. (Optional) Installation of cs-studio phoebus GUI

## Preparation

```sh
sudo apt-get update
sudo apt-get install -y build-essential git libevent-dev libz-dev libfftw3-dev libreadline-dev python3 python3-serial python-is-python3
```

```sh
git clone --branch 7.0 https://github.com/epics-base/epics-base
git clone --branch master https://github.com/epics-base/pvxs
git clone --branch master https://github.com/epics-modules/autosave
git clone --branch master https://github.com/osprey-dcs/feed-core
git clone --branch master https://github.com/osprey-dcs/pscdrv
git clone --branch main https://github.com/osprey-dcs/atf-acq-ioc
git clone https://github.com/mdavidsaver/alluvium

cat <<EOF > pvxs/configure/RELEASE.local
EPICS_BASE=\$(TOP)/../epics-base
EOF

cat <<EOF > autosave/configure/RELEASE.local
EPICS_BASE=\$(TOP)/../epics-base
EOF

cat <<EOF > feed-core/configure/RELEASE.local
EPICS_BASE=\$(TOP)/../epics-base
EOF

cat <<EOF > pscdrv/configure/RELEASE.local
EPICS_BASE=\$(TOP)/../epics-base
EOF

cat <<EOF > pscdrv/configure/CONFIG_SITE.local
USE_FFTW=YES
EOF

cat <<EOF > atf-acq-ioc/configure/RELEASE.local
AUTOSAVE=\$(TOP)/../autosave
PVXS=\$(TOP)/../pvxs
FEED=\$(TOP)/../feed-core
PSCDRV=\$(TOP)/../pscdrv
EPICS_BASE=\$(TOP)/../epics-base
EOF

# replace '10' with number of CPUs
make -C epics-base
make -C autosave
make -C pvxs
make -C feed-core
make -C pscdrv
make -C atf-acq-ioc
```

## IOC configuration

```sh
cd atf-acq-ioc/iocBoot/siocNASA_ACQ
```

Edit for example `node01.cmd` and change the value of `NASA_ACQ_BASE_IP` to eg. `192.168.79.8`.

Then run:

```sh
./node01.cmd
```

In another terminate run:

```sh
$ export PATH="$PATH:$PWD/epics-base/bin/linux-x86_64"

$ caget -S FDAS:01:GLD:image FDAS:01:GLD:FW_CODEHASH FDAS:01:APP:FW_CODEHASH
FDAS:01:GLD:image              Gold
FDAS:01:GLD:FW_CODEHASH b8ea50264fe8ccb7195b3ff14c909a2c56b085a0
FDAS:01:APP:FW_CODEHASH
```

A value of `Gold` should be shown to indicate that the IOC is communicating with the bootloader firmware.

A value of `None` indicates lack of communication.  Stop and troubleshoot.

Now boot to the application image, this may take ~30 seconds.

```sh
$ caput FDAS:01:GLD:boot 0
Old : FDAS:01:GLD:boot               Boot
New : FDAS:01:GLD:boot               Boot
```

```sh
$ caget -S FDAS:01:GLD:image FDAS:01:GLD:FW_CODEHASH FDAS:01:APP:FW_CODEHASH
FDAS:01:GLD:image              Appl
FDAS:01:GLD:FW_CODEHASH
FDAS:01:APP:FW_CODEHASH 19d434014ec88c9652fc332fa56cfe995219bbe4
```

### Alternative boot

The alluvium tool can be used to boot to the application firmware separately from the IOC.

```sh
$ python3 -m alluvium 192.168.79.8 clear
SR1 0b10011000 [SRWD  , p_err , e_err , BP2   , BP1   , bp0   , wel   , wip   ]
SR2 0b00000000 [es   , ps   ]
CR1 0b00100100 [lc1   , lc0   , TBPROT, dnu, bpnv  , TBPARM, quad  , freeze]
$ python3 -m alluvium 192.168.79.8 reboot app
```

## FPGA Application Console

The `atf-acq-ioc/scripts/console.py` script allows communication with
the application firmware expert console.
Currently this access is only necessary to configure a chassis as a timing "master" (EVG) node.

Application firmware must be running.

```sh
./atf-acq-ioc/scripts/console.py -a 192.168.79.8
```

Note: Issue `Ctrl+c` to interrupt the script.

Initially issue the `log` or `help` command to check communication.
(type the command then press Return)

The startup log output will look like:

```
log
Firmware build date: 1737417442
Software build date: 1737416340
JEDEC ID: 01 20 18
Flash SR:98 CR:24
Block protection set (SR:98).ASPR: FE7F
First DYBAR: FF
Microcontroller:
  U28: 39.5 C
  U29: 41.0 C
  Firmware: 86A9BF22
  MAC address: 12:55:55:00:1F:07
 IPv4 address: 192.168.79.7
 IPv4 netmask: 255.255.255.0
 IPv4 gateway: 192.168.79.1
 IPv4 NTP server: 192.168.79.99
FMC1 EEPROM at 0x54:
   Manufacturer: Osprey
           Name: Quartz
  Serial Number: 202
    Part Number: v2.1.1
Boot flash write protected.
```

Query current IP configuration

```
gw
 IPv4 netmask: 255.255.255.0
 IPv4 gateway: 192.168.79.1
ntp
 IPv4 NTP server: 192.168.79.99
```

Use the `gw` and `ntp` commands configure the NTP server address (**node 1/EVG only**),
netmask, and default gateway.

For a EVG node:

```
ntp 192.168.79.99 255.255.255.0
```

For all other nodes:

```
ntp 0.0.0.0 255.255.255.0
```

To clear issue `ntp 0.0.0.0`.
If the netmask is omitted, then `255.255.255.0` is used.
Acknowledge and reboot (power cycle or issue `boot` command)

When configured as a master/EVG, the node will attempt to contact the NTP server on startup.
Success looks like:

```
NTP round trip 6123341 us
Time 1739846200:3258402 after 408 us
```

Failure looks like:

```
Warning -- No response from NTP server.
```

**The master/EVG node must synchronize with the NTP server prior to any acquisition.**
