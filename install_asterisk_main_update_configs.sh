#!/bin/bash

tokens_file=/etc/asterisk/extensions_tokens.conf
EMAIL_FROM=$(grep -Po '(?<=EMAIL_FROM=).*' "$tokens_file")
EMAIL_PASS=$(grep -Po '(?<=EMAIL_PASS=).*' "$tokens_file")

chmod -R a+rwX /opt
mkdir /opt/mutt
# Define the file path
file_path="/etc/Muttrc"

# Replace the values in the file
sed -i "s/set from =/set from = \"$EMAIL_FROM\"/" "$file_path"
sed -i "s|set smtp_url = \"smtp://@smtp.gmail.com:587/\"|set smtp_url = \"smtp://$EMAIL_FROM@smtp.gmail.com:587/\"|" "$file_path"
sed -i "s/set smtp_pass =/set smtp_pass = \"$EMAIL_PASS\"/" "$file_path"

echo "Values replaced successfully."