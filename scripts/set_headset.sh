#!/usr/bin/env bash
# set_headset.sh  [type-c]

SINKS=$(pactl list short sinks)

TYPE_C_SINK=$(echo "$SINKS" | awk '/AB13X.*USB.*Audio/ {print $2}')
JACK_SINK=$(echo "$SINKS" | awk '/pci.*analog-stereo/ {print $2}')

case "${1:-jack}" in
  type-c)
    TARGET="$TYPE_C_SINK"
    ;;
  *)
    TARGET="$JACK_SINK"
    ;;
esac

[[ -z $TARGET ]] && { echo "Target sink not found!"; exit 1; }

pactl set-default-sink "$TARGET"
echo "Default output set to: $TARGET"
