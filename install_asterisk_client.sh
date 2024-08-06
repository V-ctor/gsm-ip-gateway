#!/bin/sh
################ Install for OpenWRT
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
  sed -i "s/option enabled '0'/option enabled '1'/" "/etc/config/asterisk" #Enable asterisk

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

  ./update_asterisk_server_address_interactive.sh
}

allow_RTP() {
  uci add firewall rule
  uci set firewall.@rule[-1].name='Allow-RTP'
  uci set firewall.@rule[-1].src='VPN'
  uci set firewall.@rule[-1].proto='udp'
  uci set firewall.@rule[-1].dest_port='10000:20000'
  uci set firewall.@rule[-1].target='ACCEPT'
  uci commit firewall
}

# The issue, if we have:
# 1. dongle E171 from MTS (AE171s-1), lsusb recognizes as
#  12d1:1506        Mobile Connect
# 2. and 'asterisk-chan-dongle - 2021-10-06-3d046f7d-2'
# then Asterisk can't find dongle if it is described in dongle.conf not by audio/data ports (ttyUSBx) but IMEI.
# Also Asterisk can't discover such dongle by 'dongle discovery' command. It was solved in commit https://github.com/wdoekes/asterisk-chan-dongle/commit/503dba87d726854b74b49e70679e64e6e86d5812
# but 'asterisk-chan-dongle - 2021-10-06-3d046f7d-2' does not contain it. That is why we emulate it by this modifying.
modify_chan_dongle_for_E171() {
  file_to_modify="/usr/lib/asterisk/modules/chan_dongle.so"
  sed 's/\xd1\x12\x06\x15\x03/\xd1\x12\x06\x15\x01/g' $file_to_modify.so > temp; rm $file_to_modify.so; mv temp $file_to_modify.so
}

install_for_openwrt() {
  echo "Install Asterisk for OpenWRT"
  install_dependencies_for_openwrt
  chmod 666 /dev/ttyUSB* #It could be necessary to make this changes for each dongle replug
  cp server-client/90-usb-dongle-hotplug  /etc/hotplug.d/usb/
  /etc/init.d/hotplug2 restart

  install_configs
  allow_RTP
  modify_chan_dongle_for_E171
  ./dongle_keep_alive_install.sh
  ./dongle_number_check_install.sh
  service asterisk restart
}

################ Install for deb-based distros

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

if [ -f /etc/openwrt_release ]; then
  install_for_openwrt
else
  install_for_deb
fi