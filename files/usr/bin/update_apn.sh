#!/bin/sh
SCRIPT_PATH="/usr/bin/send_at.sh"
APN="$1"
sed -i 's/^APN=.*/APN="'"$APN"'"/' $SCRIPT_PATH