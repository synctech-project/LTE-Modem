#!/bin/sh
APN="MTNIRANCELL"
echo -e "AT+QCFG="usbnet",1
" > /dev/ttyUSB2
sleep 1
echo -e "AT+QICSGP=1,1,"$APN","","",0
" > /dev/ttyUSB2
sleep 1
echo -e "AT+CGDCONT=1,"IP","$APN"
" > /dev/ttyUSB2
sleep 1
echo -e "AT+QNETDEVCTL=1,1,1
" > /dev/ttyUSB2
sleep 1