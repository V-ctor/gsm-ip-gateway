#!/bin/sh
install_dependencies_for_openwrt() {
  opkg update
  opkg install asterisk asterisk-pjsip asterisk-bridge-simple asterisk-codec-alaw asterisk-res-rtp-asterisk asterisk-app-stack
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

  source_files="pjsip_custom.conf pjsip_custom_100.conf pjsip_custom_101.conf pjsip_custom_cloud.conf extensions_custom.conf dongle.conf"
  source_dir="server-client"
  destination_dir="/etc/asterisk/"
  for source_file in $source_files; do
    # Check if the source file exists in the destination directory
    if [ ! -e "$destination_dir/$source_file" ]; then
      cp "$source_dir/$source_file" "$destination_dir"
      echo "Copied $source_file to $destination_dir"
    else
      echo "$source_file already exists in $destination_dir, skipping."
    fi
  done
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
