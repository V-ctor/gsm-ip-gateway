#!/bin/bash
DOMAIN=$1
cp -L "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" "/etc/asterisk/keys/fullchain.pem"
cp -L "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" "/etc/asterisk/keys/privkey.pem"
chown asterisk:asterisk /etc/asterisk/keys/fullchain.pem
chown asterisk:asterisk /etc/asterisk/keys/privkey.pem

echo "SSL certificate successfully updated!"