<#
================================================================================
  Test-LaptopCu.ps1  -  Kiem tra nhanh laptop cu (Windows 10/11)
--------------------------------------------------------------------------------
  Script CHI DOC (read-only): khong cai dat, khong xoa, khong sua he thong.
  Muc tieu: trong ~1 phut nam duoc tinh trang that cua may truoc khi xuong tien.

  Cach chay:
    - Cach de nhat: double-click "Run-Test.bat" (chay kem script nay).
    - Hoac mo PowerShell roi go:
        powershell -ExecutionPolicy Bypass -File .\Test-LaptopCu.ps1

  Nen chay voi quyen Administrator de doc duoc do hao mon SSD (SMART day du).
  Khong co quyen admin van chay duoc, chi thieu vai chi so o cung.

  Ket qua:
    - In ra man hinh dang PASS / CANH BAO / KEM (mau xanh/vang/do).
    - Luu mot thu muc bao cao len Desktop: "LaptopTest_<ten may>_<ngay>"
      gom: BaoCao.txt, BatteryReport.html (suc khoe pin chi tiet).
================================================================================
#>

[CmdletBinding()]
param()

# --- Cau hinh hien thi tieng Viet ---
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$ErrorActionPreference = 'SilentlyContinue'

# --- Bien tong hop ket qua ---
$script:Report  = New-Object System.Collections.Generic.List[string]
$script:Summary = New-Object System.Collections.Generic.List[object]

function Add-Line { param([string]$Text) $script:Report.Add($Text) | Out-Null; Write-Host $Text }

function Write-Status {
    param(
        [string]$Label,
        [ValidateSet('PASS','WARN','FAIL','INFO')] [string]$Level,
        [string]$Detail
    )
    $tag = switch ($Level) {
        'PASS' { '[ TOT ]   ' }
        'WARN' { '[ CANH BAO]' }
        'FAIL' { '[ KEM ]   ' }
        'INFO' { '[ THONG TIN]' }
    }
    $color = switch ($Level) {
        'PASS' { 'Green' }
        'WARN' { 'Yellow' }
        'FAIL' { 'Red' }
        'INFO' { 'Cyan' }
    }
    Write-Host $tag -ForegroundColor $color -NoNewline
    Write-Host (" {0}" -f $Label) -NoNewline
    if ($Detail) { Write-Host (" -> {0}" -f $Detail) } else { Write-Host "" }

    $script:Report.Add(("{0} {1} -> {2}" -f $tag, $Label, $Detail)) | Out-Null
    $script:Summary.Add([pscustomobject]@{ Label=$Label; Level=$Level; Detail=$Detail }) | Out-Null
}

function Section { param([string]$Title)
    $bar = "=" * 70
    Add-Line ""
    Add-Line $bar
    Add-Line ("  {0}" -f $Title)
    Add-Line $bar
}

function Test-IsAdmin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object System.Security.Principal.WindowsPrincipal($id)).IsInRole(
        [System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================================
Clear-Host
Add-Line "############################################################"
Add-Line "#        KIEM TRA LAPTOP CU - Windows 10/11               #"
Add-Line ("#        Thoi gian: {0,-37}#" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line "############################################################"

$isAdmin = Test-IsAdmin
if (-not $isAdmin) {
    Write-Status "Quyen Administrator" "WARN" "Chua chay voi quyen admin -> thieu chi so hao mon SSD. Nen chay lai bang Run-Test.bat (chon Yes khi hoi)."
}

# ----------------------------------------------------------------------------
Section "1. THONG TIN MAY (model, tuoi may, bao hanh tham khao)"
# ----------------------------------------------------------------------------
$cs   = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$os   = Get-CimInstance Win32_OperatingSystem

Write-Status "Hang / Model" "INFO" ("{0} {1}" -f $cs.Manufacturer, $cs.Model)
Write-Status "Serial Number" "INFO" ("{0}  (tra cuu bao hanh tren web hang san xuat)" -f $bios.SerialNumber)
Write-Status "Phien ban Windows" "INFO" ("{0} (build {1})" -f $os.Caption, $os.BuildNumber)

# Ngay BIOS = uoc luong tuoi may
$biosDate = $bios.ConvertToDateTime($bios.ReleaseDate)
if ($biosDate) {
    $ageYears = [math]::Round(((Get-Date) - $biosDate).TotalDays / 365.25, 1)
    $lvl = if ($ageYears -ge 6) {'WARN'} else {'INFO'}
    Write-Status "Ngay BIOS (uoc tuoi may)" $lvl ("{0:yyyy-MM-dd}  (~{1} nam tuoi - chi mang tinh tham khao)" -f $biosDate, $ageYears)
}

# Ngay cai Windows
$installDate = $os.ConvertToDateTime($os.InstallDate)
if ($installDate) {
    Write-Status "Ngay cai Windows lan cuoi" "INFO" ("{0:yyyy-MM-dd}" -f $installDate)
}

# ----------------------------------------------------------------------------
Section "2. PIN (chi so QUAN TRONG NHAT khi mua laptop cu)"
# ----------------------------------------------------------------------------
$battPresent = $true
try {
    $design = (Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData).DesignedCapacity
    $full   = (Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity).FullChargedCapacity
} catch { $battPresent = $false }

if ($design -and $full -and $design -gt 0) {
    $health = [math]::Round(($full / $design) * 100, 1)
    $wear   = [math]::Round(100 - $health, 1)
    $lvl = if ($health -ge 80) {'PASS'} elseif ($health -ge 60) {'WARN'} else {'FAIL'}
    Write-Status "Suc khoe pin (con lai)" $lvl ("{0}%  (thiet ke {1} mWh -> day du {2} mWh, hao mon {3}%)" -f $health, $design, $full, $wear)
    Add-Line "      Tham khao: >=80% tot | 60-80% trung binh | <60% nen tru gia/thay pin."
} else {
    Write-Status "Suc khoe pin" "WARN" "Khong doc duoc qua WMI - xem chi tiet trong BatteryReport.html (sinh ben duoi)."
}

# Cycle count (nhieu may khong ho tro qua WMI)
try {
    $cycles = (Get-CimInstance -Namespace root\wmi -ClassName BatteryCycleCount).CycleCount
    if ($cycles -gt 0) {
        $lvl = if ($cycles -lt 400) {'PASS'} elseif ($cycles -lt 800) {'WARN'} else {'FAIL'}
        Write-Status "So lan sac (cycle count)" $lvl ("{0} chu ky  (<400 tot | 400-800 kha | >800 chai nhieu)" -f $cycles)
    }
} catch {}

# Trang thai pin hien tai
$b = Get-CimInstance Win32_Battery
if ($b) {
    $statusMap = @{1='Dang xa (khong cam sac)';2='Dang cam dien';3='Day';4='Thap';5='Rat thap';6='Dang sac';7='Dang sac';8='Dang sac'}
    Write-Status "Trang thai pin" "INFO" ("Con {0}% - {1}" -f $b.EstimatedChargeRemaining, $statusMap[[int]$b.BatteryStatus])
} else {
    Write-Status "Pin" "FAIL" "KHONG PHAT HIEN PIN! Co the may thao pin, pin hong, hoac loi nhan dien."
}

# ----------------------------------------------------------------------------
Section "3. O CUNG / SSD (suc khoe, do hao mon, dung luong)"
# ----------------------------------------------------------------------------
$disks = Get-PhysicalDisk
foreach ($d in $disks) {
    $sizeGB = [math]::Round($d.Size/1GB, 0)
    $hd = $d.HealthStatus   # Healthy / Warning / Unhealthy
    $lvl = switch ($hd) { 'Healthy' {'PASS'} 'Warning' {'WARN'} default {'FAIL'} }
    Write-Status ("O: {0}" -f $d.FriendlyName) $lvl ("{0} | {1}GB | loai: {2}" -f $hd, $sizeGB, $d.MediaType)

    # SMART chi tiet (can quyen admin)
    if ($isAdmin) {
        $rc = $d | Get-StorageReliabilityCounter
        if ($rc) {
            if ($rc.Wear -ne $null) {
                $life = 100 - [int]$rc.Wear
                $wl = if ($life -ge 80) {'PASS'} elseif ($life -ge 50) {'WARN'} else {'FAIL'}
                Write-Status "   -> Tuoi tho SSD con lai" $wl ("{0}%  (da hao mon {1}%)" -f $life, $rc.Wear)
            }
            if ($rc.PowerOnHours -ne $null) {
                $poh = [int]$rc.PowerOnHours
                $pl = if ($poh -lt 10000) {'INFO'} else {'WARN'}
                Write-Status "   -> Gio da hoat dong" $pl ("{0:N0} gio (~{1} nam neu dung 8h/ngay)" -f $poh, [math]::Round($poh/2920,1))
            }
            if ($rc.ReadErrorstotal -gt 0 -or $rc.WriteErrorsTotal -gt 0) {
                Write-Status "   -> Loi doc/ghi" "WARN" ("Doc:{0} Ghi:{1}" -f $rc.ReadErrorsTotal, $rc.WriteErrorsTotal)
            }
        }
    }
}

# Dung luong con trong cac o
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $freeGB  = [math]::Round($_.FreeSpace/1GB,1)
    $totalGB = [math]::Round($_.Size/1GB,1)
    Write-Status ("Phan vung {0}" -f $_.DeviceID) "INFO" ("Trong {0}GB / {1}GB" -f $freeGB, $totalGB)
}

# ----------------------------------------------------------------------------
Section "4. CPU / RAM"
# ----------------------------------------------------------------------------
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
Write-Status "CPU" "INFO" ("{0} | {1} nhan / {2} luong" -f $cpu.Name.Trim(), $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors)

$ramTotalGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)
$slots = Get-CimInstance Win32_PhysicalMemory
$slotInfo = ($slots | ForEach-Object { "{0}GB-{1}MHz" -f [math]::Round($_.Capacity/1GB,0), $_.Speed }) -join ", "
$maxSlots = (Get-CimInstance Win32_PhysicalMemoryArray).MemoryDevices
$lvl = if ($ramTotalGB -ge 8) {'PASS'} else {'WARN'}
Write-Status "RAM" $lvl ("Tong {0}GB | {1} thanh: {2} | toi da {3} khe" -f $ramTotalGB, $slots.Count, $slotInfo, $maxSlots)

# ----------------------------------------------------------------------------
Section "5. MAN HINH / CARD DO HOA"
# ----------------------------------------------------------------------------
Get-CimInstance Win32_VideoController | ForEach-Object {
    Write-Status "GPU" "INFO" ("{0} | driver {1}" -f $_.Name, $_.DriverVersion)
}
$mon = Get-CimInstance Win32_VideoController | Select-Object -First 1
if ($mon.CurrentHorizontalResolution) {
    Write-Status "Do phan giai hien tai" "INFO" ("{0} x {1} @ {2}Hz" -f $mon.CurrentHorizontalResolution, $mon.CurrentVerticalResolution, $mon.CurrentRefreshRate)
}
Add-Line "      -> Mo file 'screen-test.html' (full man hinh F11) de soi diem chet & do deu mau."

# ----------------------------------------------------------------------------
Section "6. KET NOI: WiFi / Bluetooth / Cong mang"
# ----------------------------------------------------------------------------
$net = Get-CimInstance Win32_NetworkAdapter -Filter "PhysicalAdapter=True" | Where-Object { $_.Name -notmatch 'Virtual|VPN|Loopback' }
$hasWifi = $false; $hasBt = $false
foreach ($n in $net) {
    if ($n.Name -match 'Wi-?Fi|Wireless|802\.11') { $hasWifi = $true }
}
$bt = Get-PnpDevice -Class Bluetooth -Status OK -ErrorAction SilentlyContinue
if ($bt) { $hasBt = $true }
Write-Status "WiFi" ($(if($hasWifi){'PASS'}else{'WARN'})) ($(if($hasWifi){'Co card WiFi'}else{'Khong thay card WiFi'}))
Write-Status "Bluetooth" ($(if($hasBt){'PASS'}else{'WARN'})) ($(if($hasBt){'Co Bluetooth'}else{'Khong thay Bluetooth (co the bi tat)'}))

# ----------------------------------------------------------------------------
Section "7. BAN QUYEN WINDOWS"
# ----------------------------------------------------------------------------
$lic = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL"
$activated = $lic | Where-Object { $_.LicenseStatus -eq 1 }
if ($activated) {
    $desc = ($activated | Select-Object -First 1).Description
    Write-Status "Kich hoat Windows" "PASS" ("Da kich hoat ({0})" -f $desc)
} else {
    Write-Status "Kich hoat Windows" "WARN" "CHUA kich hoat ban quyen (hoi nguoi ban / co the dung key so/OEM)."
}

# ----------------------------------------------------------------------------
Section "8. BAO CAO PIN CHI TIET (powercfg)"
# ----------------------------------------------------------------------------
# Tao thu muc bao cao tren Desktop
$desktop = [Environment]::GetFolderPath('Desktop')
$safeName = ($cs.Model -replace '[^\w\-]', '_')
$outDir = Join-Path $desktop ("LaptopTest_{0}_{1}" -f $safeName, (Get-Date -Format 'yyyyMMdd_HHmm'))
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$battHtml = Join-Path $outDir "BatteryReport.html"
$null = powercfg /batteryreport /output "$battHtml" 2>$null
if (Test-Path $battHtml) {
    Write-Status "Battery report" "PASS" ("Da luu: {0}" -f $battHtml)
} else {
    Write-Status "Battery report" "WARN" "Khong tao duoc (may co the khong co pin)."
}

# ============================================================================
Section "TONG KET"
# ============================================================================
$fail = ($script:Summary | Where-Object Level -eq 'FAIL').Count
$warn = ($script:Summary | Where-Object Level -eq 'WARN').Count
$pass = ($script:Summary | Where-Object Level -eq 'PASS').Count
Add-Line ("  TOT: {0}   |   CANH BAO: {1}   |   KEM: {2}" -f $pass, $warn, $fail)
Add-Line ""
if ($fail -gt 0) {
    Write-Host "  => CO MUC 'KEM' (mau do). Can xem ky truoc khi mua!" -ForegroundColor Red
} elseif ($warn -gt 0) {
    Write-Host "  => Co vai diem can luu y (mau vang). Doc lai phia tren." -ForegroundColor Yellow
} else {
    Write-Host "  => Cac chi so tu dong deu on. Nho test thu cong theo CHECKLIST.md!" -ForegroundColor Green
}
Add-Line ""
Add-Line "  LUU Y: Script chi kiem tra phan tu dong duoc. Ban PHAI test them"
Add-Line "  thu cong (ban phim, loa, mic, webcam, cong cam, ban le...) theo CHECKLIST.md"

# Luu bao cao text
$txt = Join-Path $outDir "BaoCao.txt"
$script:Report -join "`r`n" | Out-File -FilePath $txt -Encoding UTF8
Write-Host ""
Write-Host ("Bao cao day du da luu tai: {0}" -f $outDir) -ForegroundColor Cyan
try { Start-Process $outDir } catch {}

Write-Host ""
Write-Host "Nhan Enter de dong..." -ForegroundColor DarkGray
[void](Read-Host)
