#!/bin/bash
echo "=== $(date +%T) ==="
echo "[CPU]"
TERM=dumb sensors | grep -E "Package|Core [0-3]" | head -5 | sed 's/°C.*//'

echo
echo "[RAM & Related]"
pch_raw=$(TERM=dumb sensors | awk '/pch_skylake/{f=1} f && /temp1:/{print $2; exit}')
jc42_raw=$(TERM=dumb sensors | awk '/jc42/{f=1} f && /temp1:/{print $2; exit}')
pch=$(echo "$pch_raw" | sed 's/[+]//')
jc42=$(echo "$jc42_raw" | sed 's/[+]//')
echo "PCH: ${pch}"
echo "RAM (EEPROM): ${jc42}"

echo
echo "[CPU Freq (MHz)]"
grep "cpu MHz" /proc/cpuinfo | head -4 | awk '{printf "  Core %d: %4.0f\n", NR-1, $4}'
