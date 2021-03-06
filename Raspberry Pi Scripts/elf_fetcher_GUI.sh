#!/bin/bash

ST_INT_pin=18
AVR_INT_pin=17 

echo "$ST_INT_pin" >> /sys/class/gpio/export
echo "out" >> /sys/class/gpio/gpio"$ST_INT_pin"/direction
echo "0" > /sys/class/gpio/gpio"$ST_INT_pin"/value


echo "$AVR_INT_pin" >> /sys/class/gpio/export
echo "out" >> /sys/class/gpio/gpio"$AVR_INT_pin"/direction
echo "0" > /sys/class/gpio/gpio"$AVR_INT_pin"/value

flag=0
snooze_count=0
else_count=0

while true; do
echo "0" > /sys/class/gpio/gpio"$ST_INT_pin"/value
gsutil -m cp -R gs://fotaproject_bucket/Request.xml /home/pi/
status_value=`xmlstarlet sel -T -t -m '/data/Status' -v . -n /home/pi/Request.xml`
controller_name=`xmlstarlet sel -T -t -m '/data/Target' -v . -n /home/pi/Request.xml`


if [[ $status_value = "Released" ]]
then
	if [[ $controller_name = "STM32F103" ]]
	then
		echo "in first if" >> /home/pi/debug.txt
		elf_name=`xmlstarlet sel -T -t -m '/data/FileName' -v . -n /home/pi/Request.xml`
		gsutil -m cp -R gs://fotaproject_bucket/"$elf_name" /home/pi/
		xmlstarlet ed -u '/data/Status' -v "Downloaded" </home/pi/Request.xml>/home/pi/new.xml
		mv /home/pi/new.xml /home/pi/Request.xml
		gsutil -m cp -R /home/pi/Request.xml gs://fotaproject_bucket/ 
		
		while [[ $flag -ne 1 ]]
		do
		echo `yad --title="3faret El Embedded FOTA project" --list --width=500 --height=200 --column "New Firmware for $controller_name is available. Select action" 'Flash now' 'Snooze 5 min' --no-buttons --timeout=60` > /home/pi/action.txt
		action_result=`sed -n '1{p;q}' /home/pi/action.txt`
		
		if [[ $action_result = "Flash now|" ]]
		then
			echo "in sec if" >> /home/pi/debug.txt
			echo "1" > /sys/class/gpio/gpio"$ST_INT_pin"/value
			sleep 2
			echo "0" > /sys/class/gpio/gpio"$ST_INT_pin"/value
			sleep 0.5
			python3 /home/pi/myApplications/elfParser.py /home/pi/"$elf_name"
			echo "STMF10 elf parsing" >> /home/pi/debug.txt
			rm /home/pi/"$elf_name"
			xmlstarlet ed -u '/data/Status' -v "Flashed" </home/pi/Request.xml>/home/pi/new.xml
			mv /home/pi/new.xml /home/pi/Request.xml
			gsutil -m cp -R /home/pi/Request.xml gs://fotaproject_bucket/ 	
			yad --title="3faret El Embedded FOTA project" --text="Flashing for $controller_name is done" --width=350 --height=10 --timeout=5  --dnd
			snooze_count=0		
			flag=1

		elif [[ $action_result = "Snooze 5 min|" ]]
		then
			echo "action elif" >> debug.txt
			snooze_count=$(($snooze_count+1))
			if [[ $snooze_count -eq 3 ]]
			then
				echo "action elif if" >> debug.txt	
				xmlstarlet ed -u '/data/Status' -v "Ignored" </home/pi/Request.xml>/home/pi/new.xml
				mv /home/pi/new.xml /home/pi/Request.xml
				gsutil -m cp -R /home/pi/Request.xml gs://fotaproject_bucket/ 	
				flag=1
			else
				echo "action elif else" >> debug.txt
				sleep 60
			fi
		else
			else_count=$(($else_count+1))
			if [[ $else_count -eq 3 ]]
			then
				echo "action elif if" >> debug.txt	
				xmlstarlet ed -u '/data/Status' -v "Ignored" </home/pi/Request.xml>/home/pi/new.xml
				mv /home/pi/new.xml /home/pi/Request.xml
				gsutil -m cp -R /home/pi/Request.xml gs://fotaproject_bucket/ 	
				flag=1
			else
				sleep 60
				echo "action else" >> debug.txt
			fi
 		fi
	done
	
	elif [[ $controller_name -eq "ATMEGA32" ]]
	then
		echo "in first if" >> /home/pi/debug.txt
		elf_name=`xmlstarlet sel -T -t -m '/data/FileName' -v . -n /home/pi/Request.xml`
		gsutil -m cp -R gs://fota_automotive/"$elf_name" /home/pi/
		xmlstarlet ed -u '/data/Status' -v "Downloaded" </home/pi/Request.xml>/home/pi/new.xml
		mv /home/pi/new.xml /home/pi/Request.xml
		gsutil -m cp -R /home/pi/Request.xml gs://fotaproject_bucket/ 
		
		while [[ $flag -ne 1 ]]
		do
		if [[ $(cat /sys/class/gpio/gpio"$ST_SW_pin"/value) -eq 1 ]]
		then
			echo "in sec if" >> /home/pi/debug.txt
			echo "1" > /sys/class/gpio/gpio"$AVR_INT_pin"/value
			sleep 3
			echo "0" > /sys/class/gpio/gpio"$AVR_INT_pin"/value
			python3 /home/pi/myApplications/elfParser.py /home/pi/"$elf_name"
			echo "STMF10 elf parsing" >> /home/pi/debug.txt
			xmlstarlet ed -u '/data/Status' -v "Flashed" </home/pi/Request.xml>/home/pi/new.xml
			mv /home/pi/new.xml /home/pi/Request.xml
			gsutil -m cp -R /home/pi/Request.xml gs://fotaproject_bucket/ 	

			flag=1
		fi
		done

	else
			xmlstarlet ed -u '/data/Status' -v "Error" </home/pi/Request.xml>/home/pi/new.xml
			mv /home/pi/new.xml /home/pi/Request.xml
			gsutil -m cp -R /home/pi/Request.xml gs://fotaproject_bucket/ 	
	fi
	
else
	sleep 10
fi

sleep 5
flag=0
done

#New Firmware ATMEGA32 Can boosters schematic.png
