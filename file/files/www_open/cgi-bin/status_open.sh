#!/bin/sh
echo "Content-Type: application/json"
echo ""

raw="$(/usr/share/synctechmodem/get_modem_info.sh)"

operator="--"
signal="--"
signal_dbm="--"
connection="--"

# «” Œ—«Ã „ﬁ«œÌ—
operator=$(echo "$raw" | awk -F: '/^operator/ {print $2}')
signal=$(echo "$raw" | awk -F: '/^signal:/ {print $2}')
signal_dbm=$(echo "$raw" | awk -F: '/^signal_dbm/ {print $2}')
connection=$(echo "$raw" | awk -F: '/^connection/ {print $2}')

signal_percent="--"
signal_bar="--"
if [ "$signal" -ge 0 ] 2>/dev/null && [ "$signal" -le 31 ] 2>/dev/null; then
    signal_percent=$(( signal * 100 / 31 ))
    signal_bar=$(( (signal * 5 + 15) / 31 ))
fi

# JSON »« Â— œÊ ò·Ìœ connection Ê InternetStatus
printf '{
'
printf '  "Operator": "%s",
' "$operator"
printf '  "Signal": "%s",
' "$signal"
printf '  "SignalDbm": "%s",
' "$signal_dbm"
printf '  "connection": "%s",
' "$connection"
printf '  "InternetStatus": "%s",
' "$connection"
printf '  "SignalPercent": %s,
' "$signal_percent"
printf '  "SignalBar": %s
' "$signal_bar"
printf '}
'
