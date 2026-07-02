#!/usr/bin/env bash
#
# uninstall.sh - Go bo cau hinh chong tran-RAM (earlyoom + zram + sysctl).
# Giu lai goi da cai (apt); chi tat dich vu va go file cau hinh do tool nay dat.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Can quyen root. Chay lai: sudo $0" >&2
  exit 1
fi

echo "==> Tat dich vu"
systemctl disable --now earlyoom || true
systemctl stop systemd-zram-setup@zram0.service || true

echo "==> Go file cau hinh"
rm -f /etc/sysctl.d/99-freeze-fix.conf
rm -f /etc/systemd/zram-generator.conf
# /etc/default/earlyoom thuoc goi earlyoom -> khoi phuc mac dinh neu con .bak
LATEST_BAK="$(ls -1t /etc/default/earlyoom.bak-* 2>/dev/null | head -1 || true)"
if [[ -n "${LATEST_BAK}" ]]; then
  cp -a "$LATEST_BAK" /etc/default/earlyoom
  echo "  khoi phuc /etc/default/earlyoom tu $LATEST_BAK"
fi

echo "==> Nap lai sysctl mac dinh"
systemctl daemon-reload
sysctl --system >/dev/null 2>&1 || true

echo "==> Xong. Muon go han goi: sudo apt-get remove earlyoom systemd-zram-generator"
