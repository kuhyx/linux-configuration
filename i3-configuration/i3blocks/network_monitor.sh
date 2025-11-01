#!/bin/bash

# Function to detect all active network interfaces
detect_interfaces() {
  local iface_path iface state
  for iface_path in /sys/class/net/*; do
    iface=$(basename "$iface_path")
    if [[ $iface == "lo" || ! -d "/sys/class/net/$iface" ]]; then
      continue
    fi
    if [[ -r "/sys/class/net/$iface/operstate" ]]; then
      state=$(< "/sys/class/net/$iface/operstate")
      if [[ $state == "up" ]]; then
        printf '%s\n' "$iface"
      fi
    fi
  done
}

# Detect all active network interfaces
mapfile -t interfaces < <(detect_interfaces)

# If no active interfaces are found, exit
if [ "${#interfaces[@]}" -eq 0 ]; then
  echo "No active network interfaces found"
  exit 1
fi

# Initialize total RX and TX bytes
total_rx_now=0
total_tx_now=0

# Initialize last recorded RX and TX bytes
total_last_rx=0
total_last_tx=0

# Initialize time variables
current_time=$(date +%s)
last_time=$current_time

# Iterate over each interface and accumulate RX and TX bytes
for interface in "${interfaces[@]}"; do
  rx_path="/sys/class/net/$interface/statistics/rx_bytes"
  tx_path="/sys/class/net/$interface/statistics/tx_bytes"

  if ! read -r rx_now < "$rx_path"; then
    rx_now=0
  fi
  if ! read -r tx_now < "$tx_path"; then
    tx_now=0
  fi

  state_file="/tmp/network_monitor_$interface"
  if [ -f "$state_file" ]; then
    read -r last_rx last_tx last_time < "$state_file"
  else
    last_rx=$rx_now
    last_tx=$tx_now
  fi

  total_rx_now=$((total_rx_now + rx_now))
  total_tx_now=$((total_tx_now + tx_now))
  total_last_rx=$((total_last_rx + last_rx))
  total_last_tx=$((total_last_tx + last_tx))

  # Save current RX and TX bytes for the next check
  echo "$rx_now $tx_now $current_time" > "$state_file"
done

# Calculate time difference
time_diff=$((current_time - last_time))

# Calculate total download and upload speeds in bytes per second
if ((time_diff > 0)); then
  total_rx_rate=$(((total_rx_now - total_last_rx) / time_diff))
  total_tx_rate=$(((total_tx_now - total_last_tx) / time_diff))
else
  total_rx_rate=0
  total_tx_rate=0
fi

# Convert speeds to human-readable format
rx_rate_human=$(numfmt --to=iec --suffix=B/s --padding=8 "$total_rx_rate")
tx_rate_human=$(numfmt --to=iec --suffix=B/s --padding=8 "$total_tx_rate")

# Store the result of printf into a string and echo it
printf "    %s        %s\n" "$rx_rate_human" "$tx_rate_human"
echo "#50FA7B"
