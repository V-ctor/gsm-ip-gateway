#!/bin/ash
# Here we check that dongle did not lose registration and reset dongle if lost.
# Function to reset a dongle
reset_dongle() {
    local dongle=$1
    echo "Resetting dongle: $dongle"
    asterisk -rx "dongle reset $dongle"
}

# Iterate through all dongles
for dongle in $(asterisk -rx "dongle show devices" | grep "Dongle Name" | awk '{print $3}'); do
    # Get the Cell ID of the dongle
    cell_id=$(asterisk -rx "dongle show device state $dongle" | grep "Cell ID" | awk '{print $4}')

    # Check if the Cell ID is 0
    if [ "$cell_id" -eq 0 ]; then
        reset_dongle "$dongle"
    fi
done