#!/bin/sh
#Adjust fan speed depending HDD temperatures
#Temperature thresolds
STOP_TEMP=30
SILENCE_TEMP=35
LOW_TEMP=40
MEDIUM_TEMP=45
HIGH_TEMP=50
FULL_TEMP=55

#Log fan speed changes ?
LOG=1
LOGFILE=/var/log/fanspeed.log

#Disks list
DISKS="/dev/sda /dev/sdb"

#Commands
CMD_HDDTEMP=/usr/sbin/hddtemp
AWK=/usr/bin/awk
SED=/bin/sed
QCONTROL=/usr/sbin/qcontrol
DATE=/bin/date
CAT=/bin/cat

#Code
if [ ! -f /var/run/fanspeed ] ; then
	echo "UNKNOWN" > /var/run/fanspeed
fi
OLD_FAN_SPEED=$($CAT /var/run/fanspeed)
MAX_TEMP=0 #Set initial value
for DISK in $DISKS ; do #Test each disk defined in DISKS
	HDD_TEMP=$($CMD_HDDTEMP $DISK | $SED s/..$// | $AWK '{print $4}') #Extract temperature
	if [ $HDD_TEMP -ge $MAX_TEMP ] ; then #Is the disk temperature the highest we collect ?
		MAX_TEMP=$HDD_TEMP
	fi
done

if [ $MAX_TEMP -ge $FULL_TEMP ] ; then #If temperature is over the limit, set fan speed to full
	FAN_SPEED=FULL
	$QCONTROL fanspeed full
elif [ $MAX_TEMP -ge $HIGH_TEMP ] && [ $MAX_TEMP -lt $FULL_TEMP ] ; then #Set fan speed to high if the temperature is between FULL and HIGH
	FAN_SPEED=HIGH
	$QCONTROL fanspeed high
elif [ $MAX_TEMP -ge $MEDIUM_TEMP ] && [ $MAX_TEMP -lt $HIGH_TEMP ] ; then #Set fan speed to medium if the temperature is between MEDIUM and HIGH
	FAN_SPEED=MEDIUM
	$QCONTROL fanspeed medium
elif [ $MAX_TEMP -ge $LOW_TEMP ] && [ $MAX_TEMP -lt $MEDIUM_TEMP ] ; then #Set fan speed to low if the temperature is between LOW and SILENCE
	FAN_SPEED=LOW
        $QCONTROL fanspeed low
elif [ $MAX_TEMP -ge $SILENCE_TEMP ] && [ $MAX_TEMP -lt $LOW_TEMP ] ; then #Set fan speed to silence if the temperature is between SILENCE and STOP
	FAN_SPEED=SILENCE
        $QCONTROL fanspeed silence
elif [ $MAX_TEMP -le $STOP_TEMP ] ; then #Set fan speed to stop if the temperature is below the STOP value
	FAN_SPEED=STOP
        $QCONTROL fanspeed stop
fi

if [ "$LOG" -eq 1 ] && [ "$OLD_FAN_SPEED" != "$FAN_SPEED" ] ; then
	echo "$($DATE +%F\ %H:%M:%S) : Fan speed changed from $OLD_FAN_SPEED to $FAN_SPEED - Maximum disk temperature is $MAX_TEMP" >> $LOGFILE
for DISK in $DISKS ; do
	echo "$DISK temperature is $($CMD_HDDTEMP $DISK | $SED s/..$// | $AWK '{print $4}')" >> $LOGFILE
done
fi

echo "$FAN_SPEED" > /var/run/fanspeed
