#!/bin/bash

# Detect the active WiFi interface
wifi_interface=$(iw dev | awk '$1=="Interface"{print $2}')

# If no WiFi interface is found, exit
if [ -z "$wifi_interface" ]; then
  echo "    down"
  exit 1
fi

# Get the WiFi details
wifi_info=$(iwconfig "$wifi_interface" 2> /dev/null)

# Extract the SSID and signal strength
ssid=$(echo "$wifi_info" | awk -F '"' '/ESSID/ {print $2}')
signal=$(echo "$wifi_info" | awk '/Signal level/ {print $4}' | sed 's/level=//')

# Get the IP address
ip_address=$(ip addr show "$wifi_interface" | awk '/inet / {print $2}' | cut -d/ -f1)

# Output the result
if [ -z "$ssid" ]; then
  echo "    down"
else
  echo "    $ssid ($signal dBm) $ip_address"
fi
