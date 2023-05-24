add_line() {
  if ! grep -q -F "$1" "$2"; then
    echo "$1" >>"$2"
  fi
}

install_configs() {
  add_line "#include pjsip_custom.conf" /etc/asterisk/pjsip.conf
  add_line "#include extensions_tokens.conf" /etc/asterisk/extensions.conf
  add_line "#include extensions_custom.conf" /etc/asterisk/extensions.conf
  add_line "noload => chan_sip.so" /etc/asterisk/modules.conf
  add_line "load => chan_pjsip.so" /etc/asterisk/modules.conf
  cp pjsip_custom.conf pjsip_custom_100.conf pjsip_custom_101.conf extensions_custom.conf /etc/asterisk/
}

install_dependencies() {
  apt update
  apt install asterisk
}

setup_ip_tables() {
  iptables -I INPUT -p udp -m udp --dport 5060 -j ACCEPT
  iptables -I OUTPUT -p udp -m udp --dport 5060 -j ACCEPT
  iptables -I INPUT -p udp -m udp --dport 5061 -j ACCEPT
  iptables -I OUTPUT -p udp -m udp --dport 5061 -j ACCEPT
  iptables -I INPUT -p tcp -m tcp --dport 4569 -j ACCEPT
  iptables -I OUTPUT -p tcp -m tcp --dport 4569 -j ACCEPT
  iptables -I INPUT -p udp -m udp --dport 10000:30000 -j ACCEPT
  iptables -I OUTPUT -p udp -m udp --dport 10000:30000 -j ACCEPT
}

echo "Installing standalone Asterisk server"
install_dependencies
install_configs
service asterisk restart
setup_ip_tables
./save-iptables.sh

certbot certonly --standalone --preferred-challenges http -d victor.sipme.com.au
cp /etc/letsencrypt/live/pbx.yourdomain.com/fullchain.pem /etc/asterisk/keys/server.crt
cp /etc/letsencrypt/live/pbx.yourdomain.com/privkey.pem /etc/asterisk/keys/server.key
chown asterisk:asterisk /etc/asterisk/keys/server.crt
chown asterisk:asterisk /etc/asterisk/keys/server.key

echo "Installation complete"
echo "Don't forget to setup fail2ban!"
