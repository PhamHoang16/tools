#!/usr/bin/env bash
#
# uninstall.sh - Go bo cau hinh chong tran-RAM (earlyoom + zram + sysctl).
# Giu lai goi da cai (apt); chi tat dich vu va go file cau hinh do tool nay dat.
#
# Dung --force de bo qua canh bao an toan khi tat zram (xem ben duoi).
#
set -euo pipefail

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

if [[ $EUID -ne 0 ]]; then
  echo "Can quyen root. Chay lai: sudo $0" >&2
  exit 1
fi

# Gia tri mac dinh cua kernel, dung de tra sysctl ve khi go.
# LUU Y: 'sysctl --system' chi AP DUNG cac file con lai, no KHONG revert gia tri
# da nam trong kernel. Neu chi xoa file thi swappiness van la 180 trong khi zram
# da tat -> swap cuc hang sang disk, te hon truoc khi cai. Nen phai dat lai tay.
declare -A DEFAULTS=(
  [vm.swappiness]=60
  [vm.page-cluster]=3
  [vm.watermark_scale_factor]=10
  [vm.watermark_boost_factor]=15000
)

echo "==> Kiem tra an toan truoc khi tat zram"
# Tat zram = phai doc nguoc toan bo du lieu trong do tro lai RAM. Neu luong du
# lieu nay lon hon RAM con trong, may se thrash hoac OOM ngay trong luc go -
# dung cai tinh huong tool nay sinh ra de tranh.
swap_used_kb=$(( $(awk '/SwapTotal/{print $2}' /proc/meminfo) - $(awk '/SwapFree/{print $2}' /proc/meminfo) ))
mem_avail_kb=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
printf "  swap dang dung : %6.2f GB\n" "$(awk "BEGIN{print $swap_used_kb/1048576}")"
printf "  RAM con trong  : %6.2f GB\n" "$(awk "BEGIN{print $mem_avail_kb/1048576}")"
if (( swap_used_kb > mem_avail_kb )) && (( ! FORCE )); then
  cat >&2 <<'WARN'

  DUNG LAI: swap dang dung NHIEU HON RAM con trong.
  Tat zram luc nay se phai nap nguoc du lieu vao RAM khong du cho -> treo may.

  Hay lam mot trong so nay roi chay lai:
    - Dong bot ung dung (trinh duyet) cho swap va xuong
    - Reboot roi chay ./uninstall.sh ngay sau khi dang nhap
    - Neu chac chan muon lam: sudo ./uninstall.sh --force

WARN
  exit 1
fi
echo "  OK, an toan de tiep tuc."

echo "==> Tat dich vu"
systemctl disable --now earlyoom || true
swapoff /dev/zram0 2>/dev/null || true
systemctl stop systemd-zram-setup@zram0.service || true

echo "==> Go / khoi phuc file cau hinh"
restore_or_remove() {
  # restore_or_remove() <file> - khoi phuc tu ban .bak moi nhat neu co,
  # khong thi xoa han. install.sh co backup, nen go cai phai tra lai cho dung.
  local f="$1" bak
  bak="$(ls -1t "${f}.bak-"* 2>/dev/null | head -1 || true)"
  if [[ -n "$bak" ]]; then
    cp -a "$bak" "$f"
    echo "  khoi phuc $f tu $bak"
  else
    rm -f "$f"
    echo "  xoa $f (khong co ban backup)"
  fi
}
restore_or_remove /etc/systemd/zram-generator.conf
restore_or_remove /etc/default/earlyoom
rm -f /etc/sysctl.d/99-freeze-fix.conf
echo "  xoa /etc/sysctl.d/99-freeze-fix.conf"

echo "==> Tra sysctl ve mac dinh"
for k in "${!DEFAULTS[@]}"; do
  if sysctl -wq "$k=${DEFAULTS[$k]}" 2>/dev/null; then
    echo "  $k = ${DEFAULTS[$k]}"
  else
    echo "  bo qua $k (kernel nay khong co)" >&2
  fi
done
# Chay sau cung de cac file sysctl KHAC (neu co) duoc ap dung de len tren
# gia tri mac dinh vua dat.
sysctl --system >/dev/null 2>&1 || true

systemctl daemon-reload

echo "==> Xong. Muon go han goi: sudo apt-get remove earlyoom systemd-zram-generator"
