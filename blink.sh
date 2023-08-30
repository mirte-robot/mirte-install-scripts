#!/bin/bash

BLINK_SPEED=.5
VALUE=$1
OPI=$(uname -a | grep sunxi)
OPI2=$(grep "Orange Pi Zero 2" /proc/device-tree/model)
RPI=$(grep -a "Raspberry" /proc/device-tree/model)

if [ "$RPI" ]; then
	echo none >/sys/class/leds/ACT/trigger
	echo none >/sys/class/leds/PWR/trigger
fi

red_on() {
	if [ "$OPI" ]; then
		echo 'default-on' >/sys/class/leds/orangepi\:red\:status/trigger
	elif [ "$OPI2" ]; then
		echo '255' >/sys/class/leds/orangepi\:red\:power/brightness
	elif [ "$RPI" ]; then
		echo 1 >/sys/class/leds/PWR/brightness
	fi
}
red_off() {
	if [ "$OPI" ]; then
		echo 'none' >/sys/class/leds/orangepi\:red\:status/trigger
	elif [ "$OPI2" ]; then
		echo '0' >/sys/class/leds/orangepi\:red\:power/brightness
	elif [ "$RPI" ]; then
		echo '0' >/sys/class/leds/PWR/brightness
	fi
}

green_on() {
	if [ "$OPI" ]; then
		echo 'default-on' >/sys/class/leds/orangepi\:green\:pwr/trigger
	elif [ "$OPI2" ]; then
		echo '255' >/sys/class/leds/orangepi\:green\:status/brightness
	elif [ "$RPI" ]; then
		echo 1 >/sys/class/leds/ACT/brightness
	fi
}

green_off() {
	if [ "$OPI" ]; then
		echo 'none' >/sys/class/leds/orangepi\:green\:pwr/trigger
	elif [ "$OPI2" ]; then
		echo '0' >/sys/class/leds/orangepi\:green\:status/brightness
	elif [ "$RPI" ]; then
		echo 0 >/sys/class/leds/ACT/brightness
	fi
}

if ! [ "$OPI" ]; then

	echo "Blinking"
	echo "$VALUE"

	for ((repeat = 0; repeat < 5; repeat++)); do
		# Start sequence with fast blinking both
		for ((i = 0; i < 10; i++)); do
			FAST=$(echo "scale=2; $BLINK_SPEED/20" | bc)
			green_on
			red_on
			sleep "$FAST"
			green_off
			red_off
			sleep "$FAST"
		done
		sleep $BLINK_SPEED

		for ((i = 0; i < ${#VALUE}; i++)); do
			# Next character
			green_on
			sleep $BLINK_SPEED
			green_off
			sleep $BLINK_SPEED

			if [ "${VALUE:i:1}" == "." ]; then
				green_on
				red_on
				sleep $BLINK_SPEED
				green_off
				red_off
				sleep $BLINK_SPEED
			else
				if [ "${VALUE:i:1}" == "0" ]; then
					TWICE=$(echo "scale=2; $BLINK_SPEED*2" | bc)
					sleep "$TWICE"
				else
					# Convert hex to decimal number
					DEC_VAL=$(echo "obase=10; ibase=16; ${VALUE:i:1}" | bc)

					# Blink decimal number
					for ((j = 0; j < DEC_VAL; j++)); do
						red_on
						sleep $BLINK_SPEED
						red_off
						sleep $BLINK_SPEED
					done
				fi
			fi
		done
	done

	# Reset to defaults
	green_on
	red_off
fi
