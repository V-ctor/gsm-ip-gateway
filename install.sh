install_dependencies_for_openwrt() {
  opkg update
  opkg install asterisk asterisk-pjsip asterisk-bridge-simple asterisk-codec-alaw asterisk-codec-ulaw asterisk-res-rtp-asterisk
  opkg install msmtp
  opkg install kmod-usb-serial kmod-usb-serial-wwan kmod-usb-serial-option usb-modeswitch asterisk-chan-dongle
  opkg install asterisk-func-base64 asterisk-app-system
  opkg install asterisk-codec-opus
}

add_line() {
  if ! grep -q -F "$1" "$2"; then
    echo "$1" >>"$2"
  fi
}

install_configs() {
  add_line "#include pjsip_custom.conf" /etc/asterisk/pjsip.conf
  add_line "#include extensions_tokens.conf" /etc/asterisk/extensions.conf
  add_line "#include extensions_custom.conf" /etc/asterisk/extensions.conf
  cp pjsip_custom.conf pjsip_custom_100.conf pjsip_custom_101.conf extensions_custom.conf extensions_tokens.conf  /etc/asterisk/
}

install_msmtp() {
  echo "host smtp.gmail.com
        port 587
        auth on
        tls on
        tls_starttls on
        password
        auto_from off
        user
        from
        logfile /var/log/msmtp.log
        syslog LOG_MAIL" >>/etc/msmtprc
}

install_for_openwrt() {
  echo "Install Asterisk for OpenWRT"
  install_dependencies_for_openwrt
  chmod 666 /dev/ttyUSB*
  install_configs
  install_msmtp
  service asterisk restart
}

install_dependencies_for_x86() {
  apt update
  apt install asterisk
  apt install usb-modeswitch asterisk-chan-dongle
}

install_for_x86() {
  echo "install_for_x86"
  install_dependencies_for_x86
  install_configs
}

if [ "$(uname -n)" = "OpenWrt" ]; then
  install_for_openwrt
else
  install_for_x86
fi
