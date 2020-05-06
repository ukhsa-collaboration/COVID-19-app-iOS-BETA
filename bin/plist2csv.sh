#!/bin/sh
#
# Converts the (binary) Plist files exported from the app debug screen to CSV
#

set -o pipefail
i=0
j=1
echo "Broadcast ID, Timestamp, Duration, Peripheral ID, RSSI values, RSSI intervals"
while true ; do
	PERIPHERAL_ID=$(/usr/libexec/PlistBuddy -c "Print $i" $1 | tr -d '\n')
	if [ ${PIPESTATUS[0]} -ne 0 ]; then
		echo $i
		break
	fi

	TIMESTAMP=$(/usr/libexec/PlistBuddy -c "Print $j:timestamp" $1 | tr -d '\n')
	BROADCAST_ID=$(/usr/libexec/PlistBuddy -c "Print $j:encryptedRemoteContactId" $1 | base64)
	RSSI_VALUES=$(/usr/libexec/PlistBuddy -c "Print $j:rssiValues" $1 | tr -d ' Array{}' | tr '\n' ':')
	RSSI_INTERVALS=$(/usr/libexec/PlistBuddy -c "Print $j:rssiIntervals" $1 | tr -d ' Array{}' | tr '\n' ':')
	DURATION=$(/usr/libexec/PlistBuddy -c "Print $j:duration" $1 | tr -d '\n')
	echo "$BROADCAST_ID, $TIMESTAMP, $DURATION, $PERIPHERAL_ID, $RSSI_VALUES, $RSSI_INTERVALS"
	i=$[i+2]
	j=$[j+2]
done

