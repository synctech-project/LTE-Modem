#!/bin/sh

PORT="/dev/ttyUSB2"
BAUD="115200"

MODEM_INFO=$(
  {
    echo -e "AT+CSQ\r"
    sleep 1
    echo -e "AT+COPS?\r"
    sleep 1
  } | picocom -q -b $BAUD $PORT
)

CSQ=$(echo "$MODEM_INFO" | grep "+CSQ:" | awk -F'[: ,]+' '{print $2}')
if [ -n "$CSQ" ] && [ "$CSQ" -ge 0 ] 2>/dev/null; then
  if [ "$CSQ" -lt 32 ]; then
    DBM=$(( $CSQ * 2 - 113 ))
  else
    DBM="n/a"
  fi
else
  DBM="n/a"
fi

OPERATOR=$(echo "$MODEM_INFO" | grep +COPS | sed -n 's/.*"\(.*\)".*/\1/p')

echo "operator:$OPERATOR"
echo "signal:$CSQ"
echo "signal_dbm:$DBM"
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "connection:Connected"
else
    echo "connection:Disconnected"
fi

