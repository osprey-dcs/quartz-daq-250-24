# Osprey Quartz DAQ-250-24

Open Hardware repository for Osprey DCS Quartz DAQ-250-24
distributed ADC chassis.

Revision 2

## Contents

- [3D model](chassis-rev2.stp.xz) of 2U Chassis, including Marble and Quartz PCBs
- [Bill of materials](chassis-bom-rev2.csv) for chassis assembly.
- [Wiring](chassis-wiring-rev2.kicad_sch) diagram.
- Pre-built [firmware](firmware) images

- Documents
  - Quartz [DAQ-250-24](documentation/quartz-daq-250-24-datasheet.md) datasheet
  - Quartz bench testing [report](documentation/functional-testing.md)
  - [EPICS IOC Setup](documentation/ioc-setup.md)
  - New [System Setup](documentation/system-setup.md)
  - [Chassis Setup/Recovery](documentation/chassis-setup.md)
  - [New Marble PCB](documentation/marble-bring-up-procedure.pdf) one-time factory bring-up process

## Related

- [Marble PCB](https://github.com/BerkeleyLab/Marble) schematic and artwork
- [Marble MMC](https://github.com/BerkeleyLab/Marble-MMC) firmware
- [Marble bootloader](https://github.com/BerkeleyLab/Bedrock) firmware
  - [Alluvium](https://github.com/mdavidsaver/alluvium) remote flash chip access
- [Quartz PCB](https://github.com/osprey-dcs/Quartz) schematic and artwork
- [Quartz application](https://github.com/osprey-dcs/Quartz-firmware) firmware
- [Interlock I/O PCB](https://github.com/osprey-dcs/pmod-mps-io)
