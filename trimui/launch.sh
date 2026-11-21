#!/bin/sh
# SUB-LAB launcher for the TrimUI stock system: this folder lives in the card's Apps/SUB-LAB/.
cd "$(dirname "$0")" || exit 1
export LD_LIBRARY_PATH="/usr/trimui/lib:/usr/lib:$LD_LIBRARY_PATH"
chmod +x ./sub-lab 2>/dev/null
./sub-lab /mnt/SDCARD > launch.log 2>&1
