add_line() {
  if ! grep -q -F "$1" "$2"; then
    echo "$1" >>"$2"
  fi
}

# usage: add_line_after <before string> <string to be inserted> <file>
add_line_before() {
  awk -v insert="$2" -v before="$1" '{\
    if ($0 == before) {\
        print insert\
    }\
    print\
  }' "$3" > temp_file
  mv temp_file "$3"
}

install_configs() {
  add_line "#include pjsip_custom.conf" /etc/asterisk/pjsip.conf
  add_line "#include extensions_custom.conf" /etc/asterisk/extensions.conf
  add_line "#include extensions_tokens.conf" /etc/asterisk/extensions.conf
  add_line "#include voicemail_custom.conf" /etc/asterisk/voicemail.conf
  add_line_before "[global]" "#include modules_custom.conf" /etc/asterisk/modules.conf
  cd server-main
  cp pjsip_custom.conf pjsip_custom_200.conf pjsip_custom_201.conf extensions_custom.conf modules_custom.conf voicemail_custom.conf extensions_tokens.conf /etc/asterisk/
  cp Muttrc /etc/
  cp send_last_voicemail_to_telegram.sh /usr/local/bin/
  cp send_last_voicerecord.sh /usr/local/bin/
  install_asterisk_main_update_configs.sh
}

preload_opus_lib() {
  service_file="/lib/systemd/system/asterisk.service"
  target_section="[Service]"
  inserted_line="Environment=LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libopus.so.0"

  # Check if the service file exists
  if [[ ! -f "$service_file" ]]; then
      echo "Service file not found: $service_file"
      exit 1
  fi

  # Insert the new line after the target section
  sed -i "/$target_section/a $inserted_line" "$service_file"

  echo "Line inserted successfully."
}

install_opus() {
  cd /home/ubuntu
  wget http://ftp.debian.org/debian/pool/main/a/asterisk-opus/asterisk-opus_13.7+20171009-2_arm64.deb
  dpkg -i /home/ubuntu/asterisk-opus_13.7+20171009-2_arm64.deb
  preload_opus_lib
}

install_dependencies() {
  apt update
  apt install asterisk certbot mutt
}

setup_ip_tables() {
  iptables -I INPUT -p udp -m udp -s 192.168.30.0/24 --dport 5060 -j ACCEPT
  iptables -I OUTPUT -p udp -m udp --dport 5060 -j ACCEPT
  iptables -I INPUT -p udp -m udp --dport 5061 -j ACCEPT
  iptables -I OUTPUT -p udp -m udp --dport 5061 -j ACCEPT
  iptables -I INPUT -p udp -m udp --dport 10000:30000 -j ACCEPT
  iptables -I OUTPUT -p udp -m udp --dport 10000:30000 -j ACCEPT
}

echo "Installing standalone Asterisk server"
install_dependencies
install_opus
install_configs
service asterisk restart
setup_ip_tables
./save-iptables.sh

certbot certonly --standalone --preferred-challenges http -d victor.sipme.com.au
cp -L /etc/letsencrypt/live/victor.sipme.com.au/fullchain.pem /etc/asterisk/keys/server.crt
cp -L /etc/letsencrypt/live/victor.sipme.com.au/privkey.pem /etc/asterisk/keys/server.key
chown asterisk:asterisk /etc/asterisk/keys/server.crt
chown asterisk:asterisk /etc/asterisk/keys/server.key

echo "Installation complete"
echo "Don't forget to setup fail2ban!"
