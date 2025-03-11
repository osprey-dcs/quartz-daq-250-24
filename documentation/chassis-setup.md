# Quartz Chassis Setup and Recovery

This document describes a process to discover or set
the unique identifiers and firmware of a Quartz
digitizer chassis with unknown configuration.

This process consists of the following tasks:

1. Update application firmware
1. Set IP and MAC addresses
1. Completely reprogram flash chip

## Prerequisites

1. Working Debian Linux 12 computer with internet access.
2. Quartz-DAQ-250-24 chassis
  - Marble 1.4.1 PCB
  - Quartz 1.x PCB (serial numbers less than 200)
3. Micro-USB cable
4. Fine point non-conductive stylus to operate micro-switch

## Preparation

```sh
# procedure tested with OpenOCD 0.12.0, pyserial 3.5
sudo apt-get install openocd python3-serial git

git clone https://github.com/mdavidsaver/alluvium.git
```

Download [marble.cfg](https://github.com/BerkeleyLab/Bedrock/blob/06b84d9ba8c3c41bc6aa823fadfbee9f15dfdd08/board_support/marblemini/marble.cfg#L2) or the [local copy](firmware/marble.cfg).

Download a [bootloader firmware](../firmware/marble-bootloader/) image file.

Download an [application firmware](../firmware/quartz-application/) image file.

## Program Application Firmware

The application firmware may be loaded while the bootloader firmware is running
via the alluvium utility.

```sh
$ cd alluvium
$ python3 -m alluvium 192.168.79.8 clear
$ python3 -m alluvium 192.168.79.8 erase app 8m
$ python3 -m alluvium 192.168.79.8 program app quartzV1-20241230-350d71f.bit
```

## Connect USB

Note: connecting the micro USB port will supply 3.3V power to an on-board FTDI USB to serial chip!
This may safely by done before or after connecting the main 12V power.
For the purposes of this document, connect the USB first in order to see output printed during MMC boot.

Depending on Quartz chassis revision, either plug into the front panel
USB port, or remove chassis lid and look for the USB pigtail port.

The micro USB connection on a Marble V1 PCB provides four virtual serial ports,
which will always appear in this relative order.

1. FPGA JTAG
2. Unused
3. FPGA debug UART
4. Management Microcontroller (MMC) UART

These will typically appear as `/dev/ttyUSB0` through `/dev/ttyUSB3`.
However, if eg. the host already has `/dev/ttyUSB0` for another device,
then they will appear as ttyUSB1 through ttyUSB3.
Assuming enumeration as 0 through 3, access the MMC console.

```sh
$ python -m serial /dev/ttyUSB3 115200
--- Miniterm on /dev/ttyUSB3  115200,8,N,1 ---
--- Quit: Ctrl+] | Menu: Ctrl+T | Help: Ctrl+T followed by Ctrl+H ---
```

Now switch on the chassis.  During the boot process the current
IP and MAC addresses will be printed.

## Set IP/MAC Address

The IP and MAC addresses may be changed via the MMC UART console.

While connected to the MMC UART, press `?` then Return to print a list of commands.

```
hardware board id 0x12

Build based on git commit 86a9bf22
Menu:
1 - MDIO/PHY
...
m d.d.d.d - Set IP Address
n d:d:d:d:d:d - Set MAC Address
...
```

The `m` and `n` commands will set/overwrite the addresses.

Quartz chassis are shipped with IP and MAC of the forms: `192.168.79.ddd` and `12:55:55:00:1f:XX`
where `ddd` and `XX` are the Marble PCB serial number in decimal and hexadecimal respectively.
eg. for Marble S/N 8.

```
m 192.168.79.8
n 12:55:55:00:1f:08
```

### Verify Communication

After changing the IP address, power cycle the chassis and attempt to ping.

Note: the bootloader firmware will respond to a ping (ICMP), the application firmware will not.
      So for this test first stop any Quartz IOC from communication with the chassis.

Either firmware will respond to ARP requests.
So after attempting a `ping`, also check the ARP cache.

A positive result will show a MAC address (aka. Link Layer ADDRess):

```sh
$ ip neigh
...
192.168.79.7 dev eth0 lladdr 12:55:55:00:1f:07 REACHABLE
```

A negative result will not:

```sh
$ ip neigh
...
192.168.79.90 dev eth0 INCOMPLETE
```

The bootloader firmware may also be used with the `alluvium` tool.

```
$ cd alluvium
$ python3 -m alluvium 192.168.79.8 status
SR1 0b10011000 [SRWD  , p_err , e_err , BP2   , BP1   , bp0   , wel   , wip   ]
SR2 0b00000000 [es   , ps   ]
CR1 0b00100100 [lc1   , lc0   , TBPROT, dnu, bpnv  , TBPARM, quad  , freeze]
```

## Re-program Flash Chip

**Do not perform the following unless specifically directed to do so.**

## Overwrite FPGA bootloader image

As shipped, the 16MB flash chip on a Marble is partitioned into two 8MB sections
referred to as `gold` (lower) and `app` (upper).
The upper `app` section may be overwritten remotely at will.
The lower `gold` section is not writable without physical access to a chassis.

The following is **not necessary** to program the application image!

See for technical details on [flash chip write protections](https://github.com/mdavidsaver/alluvium/blob/master/marble-protect.md).

### Disable all flash write protections

1. Power off chassis
2. Toggle SW1 closed (tab towards QSFP cage)
3. Load the bootloader bit file into FPGA RAM

Run the following, replacing `/home/user/golden-1.4.1-b8ea502.bit` with the path
to the actual path to the file downloaded earlier.

Note: openocd does not expand tilda (`~`) in path names.

```sh
openocd -f marble.cfg -c 'transport select jtag; init; xc7_program xc7.tap; pld load 0 /home/user/golden-1.4.1-b8ea502.bit; exit'
```

Success exits with zero and output ends with

```
Info : JTAG tap: xc7.tap tap/device found: 0x0364c093 (mfg: 0x049 (Xilinx), part: 0x364c, ver: 0x0)
```

Unsuccessful has a non-zero exit code with an error like:

```
Error: couldn't stat() ~/golden-1.4.1-b8ea502.bit: No such file or directory
failed loading file ~/golden-1.4.1-b8ea502.bit to pld device 0
```

Also see the "libusb permissions" section below.

On success the FPGA is now running the golden/bootloader firmware,
which will be used to program the flash chip.

4. Zero the SR1 register

This step will fail unless SW1 is closed (see above)

```sh
python3 -m alluvium 192.168.79.8 clear
python3 -m alluvium 192.168.79.8 setup --sr1 0
```

Note: `clear` in this context clears flash chip error status,
      and does not alter the contents.

5. Optional, backup flash contents

```sh
# Optional
python3 -m alluvium 192.168.79.8 read 0 16M -f backup.bin
```

This backup may be restored with:

```sh
# Optional
python3 -m alluvium 192.168.79.8 program 0 backup.bin
```

6. Bulk erase

The following will erase the entire flash chip.

```sh
# Erases entire flash!!
python3 -m alluvium 192.168.79.8 wipe
```

7. Program bootloader firmware

Write the same firmware image file to the lower part of the flash.

```sh
python3 -m alluvium 192.168.79.8 program gold /home/user/golden-1.4.1-b8ea502.bit
```

8. Optional, verify

Power cycle the chassis and re-run:

```sh
python3 -m alluvium 192.168.79.8 clear
```

9. Restore write protections

```sh
python3 -m alluvium 192.168.79.8 clear
python3 -m alluvium 192.168.79.8 setup --sr1 0b10011000
```

10. Power off chassis
11. Toggle SW1 open (tab away from QSFP cage)

12. Optional, verify

The following commands will now fail.

```sh
python3 -m alluvium 192.168.79.8 setup --sr1 0

python3 -m alluvium 192.168.79.8 erase gold 8M
```

### libusb permissions

`openocd` errors like the following indicate that the user account does not have permission
to access the USB device.

```
Error: libusb_open() failed with LIBUSB_ERROR_ACCESS
Error: no device found
Error: unable to open ftdi device with vid 0403, pid 6011, description '*', serial '*' at bus location '*'
```

Either run as super-user or location change change
the permissions of the appropriate `/dev` file.

```sh
$ lsusb
Bus 001 Device 005: ID 0403:6011 Future Technology Devices International, Ltd FT4232H Quad HS USB-UART/FIFO IC
...
$ ls -l /dev/bus/usb/001/005
crw-rw---- 1 root plugdev 189, 4 Feb 15 08:39 /dev/bus/usb/001/005
$ sudo chmod a+rw /dev/bus/usb/001/005
```

## Quartz EEPROM

The Quartz PCB includes an EEPROM which holds FMC meta-data,
including manufacturer, product, and serial number in the
[FRU](https://www.intel.com/content/www/us/en/servers/ipmi/information-storage-definition.html)
(Field Replaceable Unit) format.

The [frugy](https://pypi.org/project/frugy/) tool can produce EEPROM images
using configuration file templates present in the
[Quartz](https://github.com/osprey-dcs/Quartz/tree/quartz-1.x/Documentation/EEPROM) repository.

```sh
sudo apt-get install python3-virtualenv atftp

git clone --branch quartz-1.x https://github.com/osprey-dcs/Quartz
cd Documentation/EEPROM

virtualenv /tmp/fruenv
. /tmp/fruenv/bin/activate
pip install frugy
```

Now edit `Documentation/EEPROM/createEEPROMs.sh` to set a range of serial numbers.

```sh
./createEEPROMs.sh
```

This will produce a set of files with names like `EEPROM_010.bin` (base 10 numbering),
which are then loaded through the application firmware via. TFTP.

When writing the EEPROM, the J6 jumper on Quartz must be **closed/shorted**.

The current contents may be read with:

```sh
atftp --get -l EEPROM_rb.bin -r FMC1_EEPROM.bin
```

And written with:

```sh
atftp --put -l EEPROM_010.bin -r FMC1_EEPROM.bin
atftp --get -l EEPROM_rb.bin -r FMC1_EEPROM.bin
diff EEPROM_010.bin EEPROM_rb.bin
```

It is strongly recommended to always read back and compare after writing to the EEPROM.
