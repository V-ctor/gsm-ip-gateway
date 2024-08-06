#!/bin/ash
#Here we check that dongle hase it's number and request it if not.
# Get a list of all dongles in Asterisk
dongles=$(asterisk -rx "dongle show devices" | awk '{print $1}' | tail -n +2)

# Iterate through each dongle
for dongle in $dongles
do
    echo "$dongle"
    # Check the state of the dongle
    state=$(asterisk -rx "dongle show device state $dongle" | awk '/Subscriber Number/ {print $4}')

    # Check if the Subscriber Number is "Unknown"
    if [ "$state" == "Unknown" ]; then
        # Execute the command to get the Subscriber Number for the dongle
        asterisk -rx "dongle cmd $dongle AT+CNUM"
    fi
done