for dev in /sys/bus/usb/devices/*; do
  if [[ -f "$dev/idVendor" && -f "$dev/idProduct" ]]; then
    vendor=$(cat "$dev/idVendor")
    product=$(cat "$dev/idProduct")

    if [[ "$vendor" == "04f2" && "$product" == "b5a7" ]]; then
      echo 1 | sudo tee "$dev/authorized" > /dev/null
      echo "Camera enabled"
    fi
  fi
done
