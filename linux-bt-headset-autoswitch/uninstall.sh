#!/usr/bin/env bash
#
# uninstall.sh - Go watchdog + mic ao + danh sach app tu chuyen do install.sh dat.
# Co hieu luc hoan toan tu lan dang nhap lai tiep theo.
#
set -euo pipefail

CONF_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "==> Tat watchdog"
systemctl --user disable --now bt-headset-watchdog.timer 2>/dev/null || true
rm -f "$CONF_HOME/systemd/user/bt-headset-watchdog.service" \
      "$CONF_HOME/systemd/user/bt-headset-watchdog.timer"
systemctl --user daemon-reload

echo "==> Go file cau hinh"
rm -f "$HOME/.local/bin/bt-headset-watchdog.sh" \
      "$CONF_HOME/bt-headset-watchdog.conf" \
      "$CONF_HOME/pipewire/pipewire.conf.d/bt-headset-mic.conf" \
      "$CONF_HOME/wireplumber/policy.lua.d/11-bluetooth-autoswitch-apps.lua"
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/bt-headset-watchdog"

echo "==> Xong. Dang nhap lai de PipeWire/WirePlumber bo mic ao va danh sach app."
