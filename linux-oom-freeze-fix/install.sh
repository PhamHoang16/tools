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

# Ubuntu 22.04+ bat san systemd-oomd. Hai daemon OOM chay song song se tranh
# nhau: systemd-oomd lam viec theo cgroup + PSI va KHONG ton trong --prefer/
# --avoid cua earlyoom, nen no co the ban truoc va chon sai nan nhan.
if systemctl is-active --quiet systemd-oomd 2>/dev/null; then
  echo "CANH BAO: systemd-oomd dang chay song song voi earlyoom." >&2
  echo "          Chinh sach cua no khong ton trong --prefer/--avoid o day." >&2
  echo "          Nen chon MOT trong hai:" >&2
  echo "            sudo systemctl disable --now systemd-oomd   # dung earlyoom" >&2
  echo "          Xem muc \"systemd-oomd\" trong README." >&2
  echo >&2
fi

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
if ! systemctl restart systemd-zram-setup@zram0.service; then
  echo "CANH BAO: khong restart duoc systemd-zram-setup@zram0.service." >&2
  echo "          zram se duoc tao o lan boot ke tiep." >&2
fi

echo "==> Kiem chung"
fail=0
if systemctl is-active --quiet earlyoom; then
  echo "  OK  earlyoom dang chay"
else
  echo "  LOI earlyoom KHONG chay: journalctl -u earlyoom -n 30" >&2; fail=1
fi
if swapon --show=NAME --noheadings | grep -q '^/dev/zram0$'; then
  echo "  OK  zram0 da duoc kich hoat lam swap"
else
  echo "  LOI zram0 chua thanh swap (co the can reboot)" >&2; fail=1
fi
for kv in vm.swappiness=180 vm.page-cluster=0 vm.watermark_scale_factor=125; do
  k="${kv%%=*}"; want="${kv#*=}"; got="$(sysctl -n "$k")"
  if [[ "$got" == "$want" ]]; then echo "  OK  $k = $got"
  else echo "  LOI $k = $got (mong doi $want)" >&2; fail=1; fi
done

if (( fail )); then
  echo >&2
  echo "==> Cai DAT XONG NHUNG CO LOI o tren. Xem lai truoc khi tin tuong." >&2
  exit 1
fi

echo
echo "==> Xong, tat ca kiem chung deu dat."
echo "  zramctl ; swapon --show"
echo "  journalctl -u earlyoom -f"
echo
echo "Go cai: sudo ./uninstall.sh"
