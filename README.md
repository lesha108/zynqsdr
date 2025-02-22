# zynqsdr
LibreSDR firmware with banddata &amp; ptt outputs to GPIO

Modified by R2AJP on base of reference LibreSDR HDL design and https://github.com/hz12opensource/libresdr

Simply unpack Release files from sdimage.zip to small SD card in the root directory in order to make bootable SD.
If you wish to install firmware to flash use files from firmware.zip

This firmware modified:
1) to output banddata on GPIO1 as UART TX 9600 8N1 stream. You will get TX and RX LO frequences.
2) On GPIO2 PTT signal provided for use with SDR Console V3. Works alike F5OEO/F5UII firmware.

Reference HDL desing provides 40MHz sync using PPS, 10MHz ports unlike hz12opensource version, but miss HDL
interpolation/decimation. SATSAGEN reported does not work properly with this firmware.

To make GPIO outputs working please login to LibreSDR console and create autostart file /mnt/jffs2/autorun.sh like this, then reboot.

#!/bin/bash
ash /sbin/banddata.sh &
ash /sbin/watchconsoletx.sh &

There is template file exists /sbin/autorun_template.sh for lazy ) 

There are many files provided here that I modified in hz12opensource version and referemce HDL. By using them you can build firmware youself.
Sorry but no working makefile provided and no detailed instructions to build firmware. All files are only for reference. 