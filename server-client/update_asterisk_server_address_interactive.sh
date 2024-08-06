#!/bin/sh

addr=""
ask_for_address() {
    addr=""
    echo -n "Do you want to setup addr for $2 (Y) or skip  (N)? "
    read choice

    if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
        echo -n "Please enter the new IP/domain address: "
        read addr
#        echo "$addr"
    elif [ "$choice" = "N" ] || [ "$choice" = "n" ]; then
        echo "Skipping server address setup."
    else
        echo "Invalid choice. Please enter 'Y' or 'N'."
    fi
}

ask_for_address "Asterisk main server"
echo $addr
if [ -n "$addr" ]; then
    ./update_asterisk_server_address.sh 192.168.30.2 "$addr"
fi

ask_for_address "Asterisk client (OpenWRT) server"
if [ -n "$addr" ]; then
    ./update_asterisk_server_address.sh 192.168.30.14 $addr
fi