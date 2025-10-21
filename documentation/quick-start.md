# Quartz Quickstart Guide

A (somewhat) quick overview of the components and processes for setting up a new Quartz ADC chassis.

## Equipment

* [Electrical](system-setup.md#prerequisites)
* Computing
  * Host for running GUI
  * Linux host for IOCs (no GUI).  May combine.
  * NTPv3 server (may use Linux host)
* Software processes
  * [Quartz IOC](ioc-setup.md#prerequisites) (required)
  * Control System Studio/Phoebus GUI client

## Preparation

* Install [Quartz IOC](ioc-setup.md#prerequisites) and associated software

## Physical

cf. [Single Chassis](system-setup.md#single-chassis) standalone wiring.

1. Unbox and rack up the Quartz chassis
1. Attach ground wire
1. Plug in 12V AC/DC power adapter
1. Connect ethernet
1. Connect pulse-per-second (PPS) input from GPS/GNSS (TTL).
1. [Connect micro-USB](chassis-setup.md#connect-usb) (optional, change IP configuration)

## IP address setup

Initially, the chassis should be directly connected (or on the same subnet)
as the computer used for

1. Apply power to chassis
1. Set [IP and/or MAC addresses](chassis-setup.md#set-ipmac-address)
1. Power cycle chassis
1. Ping test with new IP address
1. Boot chassis to [Application firewmare](ioc-setup.md#ioc-configuration).
   May be done with full IOC, or alluvium CLI.
1. Use Application console to set netmask and gateway.
   For node 1 (EVG) only, also set NTP server address
1. Power cycle or reboot

## Setup IOC

1. Build [Quartz IOC](ioc-setup.md#prerequisites) and dependencies.
1. Edit `iocBoot/iocNASA_ACQ/node01.cmd` with selected [correct IP address](ioc-setup.md#ioc-configuration), then run.
1. Check `FDAS:01:GLD:image` PV
