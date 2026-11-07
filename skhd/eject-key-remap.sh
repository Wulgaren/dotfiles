#!/usr/bin/env bash
# Remap the eject key on the external Apple Keyboard to F18, because skhd has no
# eject key type (eject arrives as NX_KEYTYPE_EJECT, not a keyboard keycode).
# skhd's binding then sends Tinycast's clipboard shortcut (cmd+alt+space).
#
# hidutil mappings reset on reboot, so the LaunchAgent
# com.natios.eject-key-remap.plist runs this at login.
set -euo pipefail

exec /usr/bin/hidutil property \
  --matching '{"VendorID":0x05ac,"ProductID":0x023a}' \
  --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0xC000000B8,"HIDKeyboardModifierMappingDst":0x70000006D}]}'
