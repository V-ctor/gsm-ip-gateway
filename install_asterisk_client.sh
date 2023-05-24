install_dependencies_for_openwrt() {
  opkg update
  opkg install asterisk asterisk-pjsip asterisk-bridge-simple asterisk-codec-alaw asterisk-res-rtp-asterisk
  opkg install kmod-usb-serial kmod-usb-serial-wwan kmod-usb-serial-option usb-modeswitch asterisk-chan-dongle
  opkg install asterisk-func-base64 asterisk-app-system
}

add_line() {
  if ! grep -q -F "$1" "$2"; then
    echo "$1" >>"$2"
  fi
}

install_configs() {
  add_line "#include pjsip_custom.conf" /etc/asterisk/pjsip.conf
  add_line "#include extensions_custom.conf" /etc/asterisk/extensions.conf
  add_line "noload => chan_sip.so" /etc/asterisk/modules.conf
  add_line "load => chan_pjsip.so" /etc/asterisk/modules.conf
  cd server-client
  cp pjsip_custom.conf pjsip_custom_100.conf pjsip_custom_101.conf pjsip_custom_cloud.conf extensions_custom.conf dongle.conf /etc/asterisk/
}

install_for_openwrt() {
  echo "Install Asterisk for OpenWRT"
  install_dependencies_for_openwrt
  chmod 666 /dev/ttyUSB*
  install_configs
  service asterisk restart
}

install_dependencies_for_deb() {
  apt update
  apt install asterisk
  apt install usb-modeswitch asterisk-chan-dongle
}

install_for_deb() {
  echo "install for deb based OS"
  install_dependencies_for_deb
  install_configs
}

if [ "$(uname -n)" = "OpenWrt" ]; then
  install_for_openwrt
else
  install_for_deb
fi
