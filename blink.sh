#!/bin/bash

BLINK_SPEED=.5
VALUE=$1
OPI=$(uname -a | grep sunxi)

#TODO: also blink on raspberry pi
if ! [ $OPI ]; then

	echo "Blinking"
	echo $VALUE

	for ((repeat = 0; repeat < 5; repeat++)); do
		# Start sequence with fast blinking both
		for ((i = 0; i < 10; i++)); do
			FAST=$(echo "scale=2; $BLINK_SPEED/20" | bc)
			echo 'default-on' >/sys/class/leds/orangepi\:green\:pwr/trigger
			echo 'default-on' >/sys/class/leds/orangepi\:red\:status/trigger
			sleep $FAST
			echo 'none' >/sys/class/leds/orangepi\:green\:pwr/trigger
			echo 'none' >/sys/class/leds/orangepi\:red\:status/trigger
			sleep $FAST
		done
		sleep $BLINK_SPEED

		for ((i = 0; i < ${#VALUE}; i++)); do
			# Next character
			echo 'default-on' >/sys/class/leds/orangepi\:green\:pwr/trigger
			sleep $BLINK_SPEED
			echo 'none' >/sys/class/leds/orangepi\:green\:pwr/trigger
			sleep $BLINK_SPEED

			if [ ${VALUE:i:1} == "." ]; then
				echo 'default-on' >/sys/class/leds/orangepi\:green\:pwr/trigger
				echo 'default-on' >/sys/class/leds/orangepi\:red\:status/trigger
				sleep $BLINK_SPEED
				echo 'none' >/sys/class/leds/orangepi\:green\:pwr/trigger
				echo 'none' >/sys/class/leds/orangepi\:red\:status/trigger
				sleep $BLINK_SPEED
			else
				if [ ${VALUE:i:1} == "0" ]; then
					TWICE=$(echo "scale=2; $BLINK_SPEED*2" | bc)
					sleep $TWICE
				else
					# Convert hex to decimal number
					HEX_VAL=$(echo "obase=10; ibase=16; ${VALUE:i:1}" | bc)

					# Blink decimal number
					for ((j = 0; j < HEX_VAL; j++)); do
						echo 'default-on' >/sys/class/leds/orangepi\:red\:status/trigger
						sleep $BLINK_SPEED
						echo 'none' >/sys/class/leds/orangepi\:red\:status/trigger
						sleep $BLINK_SPEED
					done
				fi
			fi
		done
	done

	# Reset to defaults
	echo 'default-on' >/sys/class/leds/orangepi\:green\:pwr/trigger
	echo 'none' >/sys/class/leds/orangepi\:red\:status/trigger
fi
