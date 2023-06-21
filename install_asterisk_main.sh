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
  cp send_last_voicemail.sh /usr/local/bin/
  cp ussd_request_processing.sh /usr/local/bin/
  cp cert_renew_hook.sh /etc/letsencrypt/renewal-hooks/deploy
  install_asterisk_main_update_configs.sh
}

update_cron() {
  USSD_REQUEST_PROCESSING_SCRIPT=/usr/local/bin/ussd_request_processing.sh
  CRON_CMD="*/1 * * * * $USSD_REQUEST_PROCESSING_SCRIPT >/dev/null 2>&1"
  (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
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
  apt install asterisk asterisk-core-sounds-ru asterisk-core-sounds-ru-gsm asterisk-core-sounds-ru-wav asterisk-core-sounds-ru-g722 certbot mutt -y
}

setup_ip_tables() {
  iptables -I INPUT -p udp -m udp -s 192.168.30.0/24 --dport 5060 -j ACCEPT
  iptables -I OUTPUT -p udp -m udp --dport 5060 -j ACCEPT
  iptables -I INPUT -p udp -m udp --dport 5061 -j ACCEPT
  iptables -I OUTPUT -p udp -m udp --dport 5061 -j ACCEPT
  iptables -I INPUT -p udp -m udp --dport 10000:30000 -j ACCEPT
  iptables -I OUTPUT -p udp -m udp --dport 10000:30000 -j ACCEPT
}

function setUpCertBot() {
  apt-get update
  apt-get install certbot

  cp asterisk-renew-cert_hook.sh /etc/letsencrypt/renewal-hooks/post/

  # Generate SSL certificate using Certbot
  certbot certonly --standalone --preferred-challenges http -d "$1"
  if [ $? -eq 0 ]; then
      echo "Certificate renewal successful! Asterisk will be restarted soon."
      /etc/letsencrypt/renewal-hooks/post/asterisk-renew-cert_hook.sh "$1"
  else
      echo "Certificate renewal failed!"
      exit 1
  fi
}

echo "Installing standalone Asterisk server"
install_dependencies
install_opus
install_configs
update_cron
service asterisk restart
setup_ip_tables
./save-iptables.sh

setUpCertBot "victor.sipme.com.au"

echo "Installation complete"
echo "Don't forget to setup fail2ban!"
