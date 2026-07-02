#!/usr/bin/env bash
#
# install.sh - Chong "do cung khi tran RAM" cho may Linux desktop (ram thap).
#
# 3 lop:
#   1. earlyoom  - giet 1 process (uu tien tab trinh duyet) TRUOC khi kernel
#                  OOM-killer kip lam treo may.
#   2. zram      - swap nen trong RAM (zstd), nhanh hon swap file tren disk.
#   3. sysctl    - tune swappiness/watermark de phan ung som voi suc ep bo nho.
#
# Da kiem chung tren Ubuntu (GNOME, systemd), may 16GB RAM.
# Chay: sudo ./install.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$SCRIPT_DIR/config"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
  echo "Can quyen root. Chay lai: sudo $0" >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "Script nay viet cho he apt (Debian/Ubuntu). He khac: cai earlyoom +" >&2
  echo "systemd-zram-generator thu cong roi copy cac file trong config/." >&2
  exit 1
fi

backup() {
  # backup() <file> - sao luu file cu neu ton tai va khac ban moi
  local f="$1"
  if [[ -f "$f" ]]; then
    cp -a "$f" "${f}.bak-${STAMP}"
    echo "  backup: ${f}.bak-${STAMP}"
  fi
}

echo "==> [1/4] Cai goi: earlyoom, systemd-zram-generator"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y earlyoom systemd-zram-generator

echo "==> [2/4] Cau hinh earlyoom"
backup /etc/default/earlyoom
install -m 0644 "$CFG/earlyoom.default" /etc/default/earlyoom

echo "==> [3/4] Cau hinh zram + sysctl"
backup /etc/systemd/zram-generator.conf
install -m 0644 "$CFG/zram-generator.conf" /etc/systemd/zram-generator.conf

backup /etc/sysctl.d/99-freeze-fix.conf
install -m 0644 "$CFG/99-freeze-fix.conf" /etc/sysctl.d/99-freeze-fix.conf
sysctl --load=/etc/sysctl.d/99-freeze-fix.conf

echo "==> [4/4] Bat + khoi dong dich vu"
systemctl daemon-reload
systemctl enable --now earlyoom
# zram-generator tao unit tu config luc boot; kick lai ngay cho phien hien tai
systemctl restart systemd-zram-setup@zram0.service || true

echo
echo "==> Xong. Kiem tra:"
echo "  systemctl status earlyoom --no-pager"
echo "  zramctl ; swapon --show"
echo "  sysctl vm.swappiness vm.page-cluster vm.watermark_scale_factor"
echo
echo "Go cai: sudo ./uninstall.sh"
