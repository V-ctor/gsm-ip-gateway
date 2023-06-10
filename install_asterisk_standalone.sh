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
  add_line "#include extensions_tokens.conf" /etc/asterisk/extensions.conf
  add_line "#include extensions_custom.conf" /etc/asterisk/extensions.conf
  add_line_before "[global]" "#include modules_custom.conf" /etc/asterisk/modules.conf
  cp pjsip_custom.conf pjsip_custom_100.conf pjsip_custom_101.conf extensions_custom.conf modules_custom.conf /etc/asterisk/
}

install_dependencies() {
  apt update
  apt install asterisk
}

setup_ip_tables() {
  iptables -I INPUT -p udp -m udp --dport 5060 -j ACCEPT
  iptables -I OUTPUT -p udp -m udp --dport 5060 -j ACCEPT
  iptables -I INPUT -p udp -m udp --dport 10000:30000 -j ACCEPT
  iptables -I OUTPUT -p udp -m udp --dport 10000:30000 -j ACCEPT
}

echo "Installing standalone Asterisk server"
install_dependencies
install_configs
service asterisk restart
setup_ip_tables
./save-iptables.sh
echo "Installation complete"
echo "Don't forget to setup fail2ban!"
