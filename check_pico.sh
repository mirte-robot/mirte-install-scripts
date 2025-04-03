#!/bin/bash

sudo picotool verify -f ../mirte-telemetrix4rpipico/build/Telemetrix4RpiPico.uf2
if [ $? -eq 0 ]; then
    echo "Verification successful!"
else
    echo "Verification failed!"
    echo "running upload"
    sudo picotool load -f ../mirte-telemetrix4rpipico/build/telemetrix4rpipico.uf2
fi

sleep 5
# if lsusb has pico boot, then run reboot
if lsusb | grep -q "Raspberry Pi RP2 Boot"; then
    echo "Pico found, rebooting..."
    sudo picotool reboot
fi