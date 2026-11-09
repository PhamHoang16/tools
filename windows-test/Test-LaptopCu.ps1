<#
================================================================================
  Test-LaptopCu.ps1  -  Kiem tra laptop cu truoc khi mua (Windows 10/11)
--------------------------------------------------------------------------------
  Script CHI DOC (read-only): khong cai dat, khong xoa, khong sua he thong,
  khong gui du lieu di dau. Mo bang Notepad la doc duoc toan bo.

  Cach chay:
    - De nhat: double-click "Run-Test.bat" (tu xin quyen admin roi chay script nay).
    - Hoac:    powershell -ExecutionPolicy Bypass -File .\Test-LaptopCu.ps1
    - Bo qua test tai CPU 30 giay:  ... -File .\Test-LaptopCu.ps1 -NoStress

  Kiem tra tu dong (~1-2 phut):
     1. Thong tin may, serial (dau hieu thay main), link tra cau hinh goc
     2. Pin: suc khoe, pin thay the khai sai, so lan sac, bao cao powercfg
     3. O cung/SSD: suc khoe, % hao mon, gio chay, loi doc ghi
     4. CPU / RAM: dung luong that, 1 thanh hay 2 thanh (single/dual-channel), RAM han
     5. Man hinh: do phan giai GOC cua tam nen (phat hien man HD), ma tam nen
     6. Ket noi: WiFi, Bluetooth, cong LAN
     7. Ban quyen Windows
     8. May doanh nghiep: dinh domain/Azure AD/MDM/Autopilot, mat khau BIOS,
        Computrace/Absolute, BitLocker
     9. Loi an: thiet bi loi trong Device Manager, sap nguon, man hinh xanh,
        loi phan cung (WHEA), loi o dia trong nhat ky Windows
    10. Test tai CPU 30 giay: phat hien tut xung manh (tan nhiet kem)

  Ket qua: in man hinh (xanh/vang/do) + luu vao USB (thu muc BaoCao canh script):
     BaoCao.html (de doc nhat), BaoCao.txt, BatteryReport.html
  Neu USB khong ghi duoc thi luu ra Desktop.

  Ghi chu cho nguoi sua script: giu file nay CHI KY TU ASCII (khong dau) -
  Windows PowerShell 5.1 doc file khong BOM theo bang ma ANSI, co dau se vo chu.
================================================================================
#>

[CmdletBinding()]
param(
    [switch]$NoStress,
    [int]$StressSeconds = 30
)

# ============================================================================
#  HAM DANH GIA (thuan tuy, khong goi he thong) - duoc test trong dev/Test-Logic.ps1
# ============================================================================

function Get-BatteryAssessment {
    param([double]$Design, [double]$Full)
    if ($Design -le 0 -or $Full -le 0) {
        return [pscustomobject]@{ Level = 'WARN'; Health = $null
            Detail = 'Khong doc duoc dung luong pin qua WMI - xem BatteryReport.html.' }
    }
    $health = [math]::Round($Full / $Design * 100, 1)
    $wear = [math]::Round(100 - $health, 1)
    if ($health -gt 103) {
        return [pscustomobject]@{ Level = 'WARN'; Health = $health
            Detail = ("{0}% - CAO BAT THUONG (day {1} mWh > thiet ke {2} mWh). Hay gap o pin thay the hang tron (pin lo) khai sai dung luong: xem ten hang pin ben duoi + rut sac dung thu." -f $health, $Full, $Design) }
    }
    $lvl = if ($health -ge 80) { 'PASS' } elseif ($health -ge 60) { 'WARN' } else { 'FAIL' }
    [pscustomobject]@{ Level = $lvl; Health = $health
        Detail = ("{0}%  (thiet ke {1} mWh -> day {2} mWh, hao mon {3}%). Moc: >=80% tot | 60-80% tru gia | <60% nen thay pin/bo." -f $health, $Design, $Full, $wear) }
}

function Get-CycleLevel {
    param([int]$Cycles)
    if ($Cycles -lt 400) { 'PASS' } elseif ($Cycles -lt 800) { 'WARN' } else { 'FAIL' }
}

function Get-DiskHealthLevel {
    param([string]$Status)
    switch ($Status) {
        'Healthy'   { 'PASS' }
        'Warning'   { 'WARN' }
        'Unhealthy' { 'FAIL' }
        default     { 'WARN' }   # Unknown/rong: thuong do driver RAID/RST - khong ket luan duoc, KHONG phai hong
    }
}

function Get-MemoryTypeName {
    param([int]$Code)
    switch ($Code) {
        24 { 'DDR3' } 26 { 'DDR4' } 27 { 'LPDDR' } 28 { 'LPDDR2' } 29 { 'LPDDR3' }
        30 { 'LPDDR4' } 34 { 'DDR5' } 35 { 'LPDDR5' } default { '' }
    }
}

function Get-RamAssessment {
    # $Modules: cac doi tuong co Capacity (byte) va SMBIOSMemoryType (Win32_PhysicalMemory)
    param([object[]]$Modules)
    $mods = @($Modules | Where-Object { $_ -and [double]$_.Capacity -gt 0 })
    if ($mods.Count -eq 0) {
        return [pscustomobject]@{ TotalGB = 0; TypeName = ''; Soldered = $false
            CapLevel = 'WARN'; CapDetail = 'Khong doc duoc thong tin thanh RAM.'
            ChanLevel = 'INFO'; ChanDetail = 'Khong xac dinh duoc so kenh.' }
    }
    $totalGB = [math]::Round((($mods | Measure-Object -Property Capacity -Sum).Sum) / 1GB, 0)
    $codes = @($mods | ForEach-Object { [int]$_.SMBIOSMemoryType } | Select-Object -Unique)
    $typeName = (@($codes | ForEach-Object { Get-MemoryTypeName $_ } | Where-Object { $_ }) -join '/')
    $soldered = @($codes | Where-Object { $_ -in 27, 28, 29, 30, 35 }).Count -gt 0
    $sizes = @($mods | ForEach-Object { [math]::Round([double]$_.Capacity / 1GB, 0) })

    if ($totalGB -ge 16) {
        $capLevel = 'PASS'; $capDetail = "{0}GB - thoai mai cho van phong." -f $totalGB
    } elseif ($totalGB -ge 8) {
        $capLevel = 'INFO'; $capDetail = "{0}GB - du van phong co ban; nen len 16GB neu con khe." -f $totalGB
    } else {
        $capLevel = 'WARN'; $capDetail = "{0}GB - IT, Windows 10/11 se cham." -f $totalGB
    }

    if ($soldered) {
        $chanLevel = 'INFO'
        $chanDetail = "RAM {0} han chet tren main: da chay da kenh nhung KHONG nang cap duoc." -f $typeName
    } elseif ($mods.Count -eq 1) {
        $chanLevel = 'WARN'
        $chanDetail = "Chi 1 thanh {0}GB -> chay SINGLE-channel (cham hon ro, nhat la card do hoa onboard). Lap them 1 thanh CUNG dung luong neu may con khe." -f $sizes[0]
    } elseif (@($sizes | Select-Object -Unique).Count -gt 1) {
        $chanLevel = 'WARN'
        $chanDetail = "Cac thanh lech dung luong ({0} GB) -> chi dual-channel mot phan. Tot nhat la 2 thanh bang nhau." -f ($sizes -join ' + ')
    } else {
        $chanLevel = 'PASS'
        $chanDetail = "{0} thanh bang nhau ({1} GB) -> DUAL-channel." -f $mods.Count, ($sizes -join ' + ')
    }
    [pscustomobject]@{ TotalGB = $totalGB; TypeName = $typeName; Soldered = $soldered
        CapLevel = $capLevel; CapDetail = $capDetail; ChanLevel = $chanLevel; ChanDetail = $chanDetail }
}

function Test-PlaceholderSerial {
    param([string]$Serial)
    if ([string]::IsNullOrWhiteSpace($Serial)) { return $true }
    $s = $Serial.Trim()
    $s -match '(?i)to be filled|default string|system serial|chassis serial|o\.e\.m|^0+$|^none$|^n/?a$|^123456789|^x+$'
}

function Get-WarrantyUrl {
    param([string]$Manufacturer, [string]$Serial)
    if (Test-PlaceholderSerial $Serial) { return $null }
    $s = $Serial.Trim()
    if ($Manufacturer -match '(?i)dell') { return "https://www.dell.com/support/home/en-us/product-support/servicetag/$s/overview" }
    if ($Manufacturer -match '(?i)lenovo') { return 'https://pcsupport.lenovo.com/warrantylookup' }
    if ($Manufacturer -match '(?i)hp|hewlett') { return 'https://support.hp.com/vn-en/check-warranty' }
    if ($Manufacturer -match '(?i)asus') { return 'https://www.asus.com/support/warranty-status-inquiry/' }
    if ($Manufacturer -match '(?i)acer') { return 'https://www.acer.com/us-en/support/warranty' }
    $null
}

function ConvertFrom-WmiCharArray {
    # WmiMonitorID tra ve ten hang/ma tam nen dang mang so UInt16
    param($Codes)
    if (-not $Codes) { return '' }
    ((@($Codes) | Where-Object { [int]$_ -ne 0 }) | ForEach-Object { [char][int]$_ }) -join ''
}

function Test-InternalPanel {
    # VideoOutputTechnology: 6=LVDS, 11=eDP, 13=UDI embedded, 0x80000000=INTERNAL
    param([int64]$Vot)
    ($Vot -in 6, 11, 13) -or ($Vot -eq 2147483648) -or ($Vot -eq -2147483648)
}

function Get-PanelAssessment {
    param([int]$Width, [int]$Height)
    if ($Width -le 0 -or $Height -le 0) {
        return [pscustomobject]@{ Level = 'INFO'; Detail = 'Khong doc duoc do phan giai goc - xem Settings > Display.' }
    }
    if ($Width -lt 1920) {
        return [pscustomobject]@{ Level = 'WARN'
            Detail = ("Do phan giai GOC {0}x{1} - THAP HON Full HD (thuong la man HD tam nen TN re tien, nhin nghieng bi am mau)." -f $Width, $Height) }
    }
    [pscustomobject]@{ Level = 'PASS'; Detail = ("Do phan giai goc {0}x{1}." -f $Width, $Height) }
}

function Get-ThrottleAssessment {
    # $Samples: % hieu nang CPU so voi xung danh dinh (Win32 PercentProcessorPerformance), lay moi ~2 giay
    param([double[]]$Samples, [bool]$OnBattery)
    $s = @($Samples | Where-Object { $_ -gt 0 })
    if ($s.Count -lt 4) {
        return [pscustomobject]@{ Level = 'INFO'; Peak = 0; Sustained = 0; Detail = 'Khong du so lieu xung CPU de danh gia.' }
    }
    $peak = [math]::Round(($s | Measure-Object -Maximum).Maximum, 0)
    $tail = $s[($s.Count - 3)..($s.Count - 1)]
    $sustained = [math]::Round(($tail | Measure-Object -Average).Average, 0)
    $detail = "Xung dinh {0}%, duy tri cuoi bai test {1}% so voi xung danh dinh." -f $peak, $sustained
    if ($sustained -lt 60) {
        if ($OnBattery) {
            return [pscustomobject]@{ Level = 'INFO'; Peak = $peak; Sustained = $sustained
                Detail = $detail + ' May dang chay PIN nen bi gioi han - cam sac roi chay lai.' }
        }
        return [pscustomobject]@{ Level = 'WARN'; Peak = $peak; Sustained = $sustained
            Detail = $detail + ' TUT XUNG MANH khi tai nang: nghi bui/keo tan nhiet kho, quat yeu, hoac sac khong du cong suat.' }
    }
    [pscustomobject]@{ Level = 'PASS'; Peak = $peak; Sustained = $sustained
        Detail = $detail + ' Binh thuong (laptop mong tut tu xung dinh xuong la chuyen thuong; chi lo khi duoi ~60%).' }
}

function Get-Verdict {
    param([object[]]$Summary)
    $fail = @($Summary | Where-Object { $_.Level -eq 'FAIL' }).Count
    $warn = @($Summary | Where-Object { $_.Level -eq 'WARN' }).Count
    if ($fail -gt 0) {
        return [pscustomobject]@{ Level = 'FAIL'; Fail = $fail; Warn = $warn
            Text = 'CO MUC KEM (do) - xem ky tung muc, nhieu kha nang nen BO hoac tra gia manh.' }
    }
    if ($warn -gt 0) {
        return [pscustomobject]@{ Level = 'WARN'; Fail = $fail; Warn = $warn
            Text = 'Co diem can luu y (vang) - hoi nguoi ban va dung lam co tra gia.' }
    }
    [pscustomobject]@{ Level = 'PASS'; Fail = 0; Warn = 0
        Text = 'Phan kiem tra tu dong deu on - tiep tuc test thu cong theo CHECKLIST.md.' }
}

function ConvertTo-HtmlReport {
    param([object[]]$Summary, [hashtable]$Meta)
    $enc = { param($t) [System.Net.WebUtility]::HtmlEncode([string]$t) }
    $linkify = { param($t) [regex]::Replace($t, '(https?://[^\s<"]+)', '<a href="$1" target="_blank">$1</a>') }
    $verdict = Get-Verdict $Summary
    $pass = @($Summary | Where-Object { $_.Level -eq 'PASS' }).Count

    $css = @'
body{font-family:Segoe UI,Arial,sans-serif;margin:0;background:#f4f5f7;color:#1d1d1f}
.wrap{max-width:1000px;margin:0 auto;padding:20px}
h1{font-size:22px;margin:0 0 4px}
.meta{color:#555;font-size:14px;margin-bottom:16px}
.verdict{padding:14px 18px;border-radius:10px;font-size:17px;font-weight:600;margin-bottom:8px}
.v-PASS{background:#e3f6e8;color:#11632b}.v-WARN{background:#fff4d6;color:#7a5200}.v-FAIL{background:#fde4e4;color:#9b1c1c}
.counts{font-size:14px;margin-bottom:18px;color:#444}
h2{font-size:16px;margin:22px 0 6px;padding-bottom:4px;border-bottom:2px solid #d0d4da}
table{width:100%;border-collapse:collapse;background:#fff;border-radius:8px;overflow:hidden}
td{padding:7px 10px;border-bottom:1px solid #eceef1;vertical-align:top;font-size:14px}
td.tag{width:92px;font-weight:700;white-space:nowrap}
td.lbl{width:230px;font-weight:600}
tr.PASS td.tag{color:#11632b}tr.WARN td.tag{color:#a06c00}tr.FAIL td.tag{color:#b42318}tr.INFO td.tag{color:#1d5fa8}
tr.WARN{background:#fffbea}tr.FAIL{background:#fff1f1}
tr.HINT td{color:#666;font-size:13px;font-style:italic}
.issues li{margin:4px 0}
.foot{margin-top:24px;color:#666;font-size:13px}
'@
    $tagText = @{ PASS = 'TOT'; WARN = 'CANH BAO'; FAIL = 'KEM'; INFO = 'THONG TIN'; HINT = '' }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<!DOCTYPE html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
    [void]$sb.Append('<title>Bao cao test laptop - ' + (& $enc $Meta.Model) + '</title><style>' + $css + '</style></head><body><div class="wrap">')
    [void]$sb.Append('<h1>Bao cao test laptop cu: ' + (& $enc $Meta.Model) + '</h1>')
    [void]$sb.Append('<div class="meta">Serial: ' + (& $enc $Meta.Serial) + ' &middot; ' + (& $enc $Meta.Time) + '</div>')
    [void]$sb.Append('<div class="verdict v-' + $verdict.Level + '">' + (& $enc $verdict.Text) + '</div>')
    [void]$sb.Append('<div class="counts">TOT: ' + $pass + ' &middot; CANH BAO: ' + $verdict.Warn + ' &middot; KEM: ' + $verdict.Fail + '</div>')

    $issues = @($Summary | Where-Object { $_.Level -in 'FAIL', 'WARN' })
    if ($issues.Count -gt 0) {
        [void]$sb.Append('<h2>Can hoi nguoi ban / dung de tra gia</h2><ul class="issues">')
        foreach ($it in $issues) {
            [void]$sb.Append('<li><b>[' + $tagText[$it.Level] + '] ' + (& $enc $it.Label) + ':</b> ' + (& $linkify (& $enc $it.Detail)) + '</li>')
        }
        [void]$sb.Append('</ul>')
    }

    $sections = @($Summary | ForEach-Object { $_.Section } | Select-Object -Unique)
    foreach ($sec in $sections) {
        [void]$sb.Append('<h2>' + (& $enc $sec) + '</h2><table>')
        foreach ($it in @($Summary | Where-Object { $_.Section -eq $sec })) {
            [void]$sb.Append('<tr class="' + $it.Level + '"><td class="tag">' + $tagText[$it.Level] + '</td><td class="lbl">' +
                (& $enc $it.Label) + '</td><td>' + (& $linkify (& $enc $it.Detail)) + '</td></tr>')
        }
        [void]$sb.Append('</table>')
    }
    [void]$sb.Append('<div class="foot">Script chi kiem tra phan tu dong duoc. Van PHAI test tay: man hinh (screen-test.html), ban phim (keyboard-test.html), loa/mic/webcam (media-test.html), cong cam, ban le, pin phong... theo CHECKLIST.md.</div>')
    [void]$sb.Append('</div></body></html>')
    $sb.ToString()
}

# Dot-source (". .\Test-LaptopCu.ps1") chi nap cac ham o tren de test, khong chay kiem tra.
if ($MyInvocation.InvocationName -eq '.') { return }

# ============================================================================
#  HAM HIEN THI / GHI BAO CAO
# ============================================================================
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$ErrorActionPreference = 'SilentlyContinue'

$script:Report = New-Object System.Collections.Generic.List[string]
$script:Summary = New-Object System.Collections.Generic.List[object]
$script:CurrentSection = ''

function Add-Line { param([string]$Text) $script:Report.Add($Text) | Out-Null; Write-Host $Text }

function Write-Status {
    param(
        [string]$Label,
        [ValidateSet('PASS', 'WARN', 'FAIL', 'INFO')] [string]$Level,
        [string]$Detail
    )
    $tag = switch ($Level) {
        'PASS' { '[ TOT ]     ' }
        'WARN' { '[ CANH BAO ]' }
        'FAIL' { '[ KEM ]     ' }
        'INFO' { '[ THONG TIN]' }
    }
    $color = switch ($Level) { 'PASS' { 'Green' } 'WARN' { 'Yellow' } 'FAIL' { 'Red' } 'INFO' { 'Cyan' } }
    Write-Host $tag -ForegroundColor $color -NoNewline
    Write-Host (" {0}" -f $Label) -NoNewline
    if ($Detail) { Write-Host (" -> {0}" -f $Detail) } else { Write-Host '' }
    $script:Report.Add(("{0} {1} -> {2}" -f $tag, $Label, $Detail)) | Out-Null
    $script:Summary.Add([pscustomobject]@{ Section = $script:CurrentSection; Label = $Label; Level = $Level; Detail = $Detail }) | Out-Null
}

function Write-Hint {
    param([string]$Text)
    Write-Host ("      -> {0}" -f $Text) -ForegroundColor DarkGray
    $script:Report.Add(("      -> {0}" -f $Text)) | Out-Null
    $script:Summary.Add([pscustomobject]@{ Section = $script:CurrentSection; Label = ''; Level = 'HINT'; Detail = $Text }) | Out-Null
}

function Section {
    param([string]$Title)
    $script:CurrentSection = $Title
    $bar = '=' * 72
    Add-Line ''
    Add-Line $bar
    Add-Line ("  {0}" -f $Title)
    Add-Line $bar
}

function Test-IsAdmin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object System.Security.Principal.WindowsPrincipal($id)).IsInRole(
        [System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-ReportDir {
    # Uu tien luu vao USB (canh script) de mang ve; khong ghi duoc thi ra Desktop.
    param([string]$Name)
    $bases = @()
    if ($PSScriptRoot) { $bases += (Join-Path $PSScriptRoot 'BaoCao') }
    $bases += [Environment]::GetFolderPath('Desktop')
    foreach ($b in $bases) {
        try {
            $dir = Join-Path $b $Name
            New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null
            $probe = Join-Path $dir '.ghi-thu'
            Set-Content -Path $probe -Value 'ok' -ErrorAction Stop
            Remove-Item $probe -Force -ErrorAction SilentlyContinue
            return $dir
        } catch {}
    }
    $env:TEMP
}

function Get-EventCount {
    param([string[]]$Provider, [int[]]$Id, [int[]]$Level, [datetime]$Since)
    $f = @{ LogName = 'System'; StartTime = $Since }
    if ($Provider) { $f.ProviderName = $Provider }
    if ($Id) { $f.Id = $Id }
    if ($Level) { $f.Level = $Level }
    @(Get-WinEvent -FilterHashtable $f -ErrorAction SilentlyContinue).Count
}

function Get-BiosPasswordInfo {
    param([string]$Maker)
    $set = @()
    if ($Maker -match '(?i)dell') {
        $pw = @(Get-CimInstance -Namespace 'root/dcim/sysman/wmisecurity' -ClassName PasswordObject -ErrorAction SilentlyContinue)
        if ($pw.Count -gt 0) {
            $set = @($pw | Where-Object { [int]$_.IsPasswordSet -eq 1 } | ForEach-Object { $_.NameId })
            return [pscustomobject]@{ Readable = $true; SetNames = $set }
        }
    } elseif ($Maker -match '(?i)hp|hewlett') {
        $pw = @(Get-CimInstance -Namespace 'root/HP/InstrumentedBIOS' -ClassName HP_BIOSPassword -ErrorAction SilentlyContinue)
        if ($pw.Count -gt 0) {
            $set = @($pw | Where-Object { [int]$_.IsSet -eq 1 } | ForEach-Object { $_.Name })
            return [pscustomobject]@{ Readable = $true; SetNames = $set }
        }
    } elseif ($Maker -match '(?i)lenovo') {
        $pw = Get-CimInstance -Namespace 'root/wmi' -ClassName Lenovo_BiosPasswordSettings -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($pw) {
            $st = [int]$pw.PasswordState
            if ($st -band 1) { $set += 'Power-on' }
            if ($st -band 2) { $set += 'Supervisor' }
            if ($st -band 4) { $set += 'HDD user' }
            if ($st -band 8) { $set += 'HDD master' }
            if ($st -band 64) { $set += 'System management' }
            return [pscustomobject]@{ Readable = $true; SetNames = $set }
        }
    }
    [pscustomobject]@{ Readable = $false; SetNames = @() }
}

function Invoke-CpuStress {
    # Ep tat ca luong CPU trong $Seconds giay, lay mau % xung so voi danh dinh moi 2 giay.
    param([int]$Seconds = 30)
    $n = [Environment]::ProcessorCount
    $pool = [runspacefactory]::CreateRunspacePool(1, $n)
    $pool.Open()
    $work = {
        param($sec)
        $end = [DateTime]::UtcNow.AddSeconds($sec)
        $x = 0.0
        while ([DateTime]::UtcNow -lt $end) {
            for ($j = 1; $j -lt 200000; $j++) { $x += [math]::Sqrt($j) }
        }
        $x
    }
    $jobs = @()
    for ($i = 0; $i -lt $n; $i++) {
        $ps = [powershell]::Create()
        $ps.RunspacePool = $pool
        [void]$ps.AddScript($work).AddArgument($Seconds)
        $jobs += [pscustomobject]@{ PS = $ps; Handle = $ps.BeginInvoke() }
    }
    $samples = New-Object System.Collections.Generic.List[double]
    $nominal = 0
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 2
        $p = Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -Filter "Name='_Total'" -ErrorAction SilentlyContinue
        if ($p) {
            $samples.Add([double]$p.PercentProcessorPerformance)
            if ($p.ProcessorFrequency) { $nominal = [int]$p.ProcessorFrequency }
        }
        Write-Host '.' -NoNewline
    }
    Write-Host ''
    foreach ($j in $jobs) { try { [void]$j.PS.EndInvoke($j.Handle) } catch {}; $j.PS.Dispose() }
    $pool.Close(); $pool.Dispose()
    [pscustomobject]@{ Samples = $samples.ToArray(); NominalMHz = $nominal }
}

# ============================================================================
#  BAT DAU KIEM TRA
# ============================================================================
Clear-Host
Add-Line '########################################################################'
Add-Line '#              KIEM TRA LAPTOP CU - Windows 10/11                      #'
Add-Line ("#              Thoi gian: {0,-45}#" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line '########################################################################'

$isAdmin = Test-IsAdmin
$cs = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$os = Get-CimInstance Win32_OperatingSystem
$maker = [string]$cs.Manufacturer
$model = [string]$cs.Model
$serial = ([string]$bios.SerialNumber).Trim()

$safeName = (("{0}_{1}" -f $model, $serial) -replace '[^\w\-]', '_')
$outDir = Get-ReportDir -Name ("{0}_{1}" -f $safeName, (Get-Date -Format 'yyyyMMdd_HHmm'))

# ----------------------------------------------------------------------------
Section '1. THONG TIN MAY'
# ----------------------------------------------------------------------------
if (-not $isAdmin) {
    Write-Status 'Quyen Administrator' 'WARN' 'Chua chay voi quyen admin -> thieu chi so SSD, BitLocker, mat khau BIOS. Chay lai bang Run-Test.bat va bam Yes.'
}
Write-Status 'Hang / Model' 'INFO' ("{0} {1}" -f $maker, $model)
if (Test-PlaceholderSerial $serial) {
    Write-Status 'Serial / Service Tag' 'WARN' ("'{0}' - serial trong hoac mac dinh: dau hieu da THAY MAINBOARD hoac nap lai BIOS. Hoi ro nguon goc." -f $serial)
} else {
    Write-Status 'Serial / Service Tag' 'INFO' ("{0}  -> phai TRUNG voi tem duoi day may va serial trong BIOS (F2)." -f $serial)
}
$wUrl = Get-WarrantyUrl -Manufacturer $maker -Serial $serial
if ($wUrl) {
    Write-Status 'Tra cau hinh goc / bao hanh' 'INFO' $wUrl
    if ($maker -match '(?i)dell') {
        Write-Hint 'Trang Dell cho xem cau hinh LUC XUAT XUONG (man hinh, den phim, pin, ngay giao). Lech voi may thuc te = may da bi thay do.'
    } else {
        Write-Hint ("Nhap serial {0} vao trang tren de xem ngay san xuat va cau hinh goc." -f $serial)
    }
}
Write-Status 'Windows' 'INFO' ("{0} (build {1})" -f $os.Caption, $os.BuildNumber)

$biosDate = $null
try { $biosDate = $bios.ReleaseDate } catch {}
Write-Status 'BIOS' 'INFO' ("Phien ban {0}, ngay {1:yyyy-MM-dd}. Day la ngay CAP NHAT BIOS, khong phai ngay san xuat." -f $bios.SMBIOSBIOSVersion, $biosDate)

$installDate = $os.InstallDate
$daysSinceInstall = $null
if ($installDate) {
    $daysSinceInstall = [int]((Get-Date) - $installDate).TotalDays
    Write-Status 'Ngay cai Windows' 'INFO' ("{0:yyyy-MM-dd} ({1} ngay truoc)" -f $installDate, $daysSinceInstall)
    if ($daysSinceInstall -lt 30) {
        Write-Hint 'Windows moi cai -> nhat ky loi (muc 9) va lich su pin co it du lieu, KHONG chung minh may sach.'
    }
}

$tpm = Get-CimInstance -Namespace 'root/cimv2/Security/MicrosoftTpm' -ClassName Win32_Tpm -ErrorAction SilentlyContinue
if ($tpm) {
    $tpmVer = ([string]$tpm.SpecVersion -split ',')[0]
    Write-Status 'TPM' 'INFO' ("Co TPM {0} (Windows 11 can TPM 2.0)" -f $tpmVer)
} elseif ($isAdmin) {
    Write-Status 'TPM' 'WARN' 'Khong thay TPM - co the bi tat trong BIOS; Windows 11 can TPM 2.0.'
}
$sb = $null
try { $sb = Confirm-SecureBootUEFI -ErrorAction Stop } catch {}
if ($null -ne $sb) { Write-Status 'Secure Boot' 'INFO' ($(if ($sb) { 'Dang bat' } else { 'Dang tat' })) }

# ----------------------------------------------------------------------------
Section '2. PIN (chi so QUAN TRONG NHAT khi mua laptop cu)'
# ----------------------------------------------------------------------------
$bStatic = @(Get-CimInstance -Namespace 'root/wmi' -ClassName BatteryStaticData -ErrorAction SilentlyContinue)
$bFull = @(Get-CimInstance -Namespace 'root/wmi' -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue)
$design = [double](($bStatic | Measure-Object -Property DesignedCapacity -Sum).Sum)
$full = [double](($bFull | Measure-Object -Property FullChargedCapacity -Sum).Sum)
$ba = Get-BatteryAssessment -Design $design -Full $full
Write-Status 'Suc khoe pin (con lai)' $ba.Level $ba.Detail

foreach ($bs in $bStatic) {
    $bm = ([string]$bs.ManufactureName).Trim()
    $bn = ([string]$bs.DeviceName).Trim()
    if ($bm -or $bn) {
        Write-Status 'Thong tin pin' 'INFO' ("Ten: {0} | Hang san xuat pin: {1} | SN: {2}" -f $bn, $bm, ([string]$bs.SerialNumber).Trim())
    }
}
if ($bStatic.Count -gt 0) {
    Write-Hint 'Pin zin thuong ghi hang that (VD Dell: SMP, LGC, SWD, BYD, Samsung SDI...). Ten la/trong/vo nghia + suc khoe 100% tron = nghi pin lo.'
}

$cyc = @(Get-CimInstance -Namespace 'root/wmi' -ClassName BatteryCycleCount -ErrorAction SilentlyContinue)
$cycles = [int](($cyc | Measure-Object -Property CycleCount -Sum).Sum)
if ($cycles -gt 0) {
    Write-Status 'So lan sac (cycle count)' (Get-CycleLevel $cycles) ("{0} chu ky  (<400 tot | 400-800 kha | >800 chai nhieu)" -f $cycles)
}

$onBattery = $false
$b = Get-CimInstance Win32_Battery | Select-Object -First 1
if ($b) {
    $statusMap = @{ 1 = 'Dang xa (KHONG cam sac)'; 2 = 'Dang cam dien'; 3 = 'Day'; 4 = 'Thap'; 5 = 'Rat thap'; 6 = 'Dang sac'; 7 = 'Dang sac'; 8 = 'Dang sac'; 9 = 'Dang sac'; 11 = 'Sac mot phan' }
    $onBattery = ([int]$b.BatteryStatus -eq 1)
    Write-Status 'Trang thai pin' 'INFO' ("Con {0}% - {1}" -f $b.EstimatedChargeRemaining, $statusMap[[int]$b.BatteryStatus])
} else {
    Write-Status 'Pin' 'FAIL' 'KHONG PHAT HIEN PIN! May da thao pin, pin hong, hoac loi nhan dien.'
}

$battHtml = Join-Path $outDir 'BatteryReport.html'
$null = powercfg /batteryreport /output "$battHtml" 2>$null
if (Test-Path $battHtml) {
    Write-Status 'Battery report' 'PASS' ("Da luu: {0}" -f $battHtml)
    Write-Hint 'Trong BatteryReport.html xem muc "Battery capacity history" (pin tut nhanh?) va "Battery life estimates".'
} else {
    Write-Status 'Battery report' 'WARN' 'Khong tao duoc (may co the khong co pin).'
}

# ----------------------------------------------------------------------------
Section '3. O CUNG / SSD'
# ----------------------------------------------------------------------------
$allDisks = @(Get-PhysicalDisk)
$disks = @($allDisks | Where-Object { $bt = "$($_.BusType)"; -not ($bt -eq 'USB' -or $bt -eq '7') })
$usbDisks = @($allDisks | Where-Object { $bt = "$($_.BusType)"; ($bt -eq 'USB' -or $bt -eq '7') })
if ($usbDisks.Count -gt 0) {
    Write-Hint ("Bo qua o USB dang cam: {0}" -f (($usbDisks | ForEach-Object { $_.FriendlyName }) -join ', '))
}
if ($disks.Count -eq 0) {
    Write-Status 'O cung trong may' 'WARN' 'Khong doc duoc danh sach o - kiem tra bang CrystalDiskInfo.'
}
foreach ($d in $disks) {
    $sizeGB = [math]::Round($d.Size / 1GB, 0)
    $hs = "$($d.HealthStatus)"
    $lvl = Get-DiskHealthLevel $hs
    $note = if ($lvl -eq 'WARN' -and $hs -ne 'Warning') { ' (Windows khong doc duoc suc khoe - thuong do driver RAID/RST; mo CrystalDiskInfo de xem)' } else { '' }
    Write-Status ("O: {0}" -f $d.FriendlyName) $lvl ("{0} | {1}GB | {2} | {3}{4}" -f $hs, $sizeGB, $d.MediaType, $d.BusType, $note)

    if ($isAdmin) {
        $rc = $d | Get-StorageReliabilityCounter
        if ($rc) {
            if ($null -ne $rc.Wear -and $rc.Wear -gt 0) {
                $life = 100 - [int]$rc.Wear
                $wl = if ($life -ge 80) { 'PASS' } elseif ($life -ge 50) { 'WARN' } else { 'FAIL' }
                Write-Status '   -> Tuoi tho SSD con lai' $wl ("{0}%  (da hao mon {1}%)" -f $life, $rc.Wear)
            } elseif ($rc.Wear -eq 0) {
                Write-Status '   -> Tuoi tho SSD con lai' 'INFO' 'O bao hao mon 0% - hoac rat moi, hoac o khong bao chi so nay (xem CrystalDiskInfo).'
            }
            if ($null -ne $rc.PowerOnHours) {
                $poh = [int]$rc.PowerOnHours
                $pl = if ($poh -lt 10000) { 'INFO' } else { 'WARN' }
                Write-Status '   -> Gio da hoat dong' $pl ("{0:N0} gio (~{1} nam neu dung 8h/ngay)" -f $poh, [math]::Round($poh / 2920, 1))
            }
            if ($rc.Temperature -gt 0) {
                $tl = if ($rc.Temperature -ge 70) { 'WARN' } else { 'INFO' }
                Write-Status '   -> Nhiet do o' $tl ("{0} do C" -f $rc.Temperature)
            }
            if ($rc.ReadErrorsUncorrected -gt 0 -or $rc.WriteErrorsUncorrected -gt 0) {
                Write-Status '   -> Loi KHONG sua duoc' 'FAIL' ("Doc:{0} Ghi:{1} - o dang hong dan" -f $rc.ReadErrorsUncorrected, $rc.WriteErrorsUncorrected)
            } elseif ($rc.ReadErrorsTotal -gt 0 -or $rc.WriteErrorsTotal -gt 0) {
                Write-Status '   -> Loi doc/ghi' 'WARN' ("Doc:{0} Ghi:{1}" -f $rc.ReadErrorsTotal, $rc.WriteErrorsTotal)
            }
        }
    }
}
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
    Write-Status ("Phan vung {0}" -f $_.DeviceID) 'INFO' ("Trong {0}GB / {1}GB" -f [math]::Round($_.FreeSpace / 1GB, 1), [math]::Round($_.Size / 1GB, 1))
}

# ----------------------------------------------------------------------------
Section '4. CPU / RAM'
# ----------------------------------------------------------------------------
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
Write-Status 'CPU' 'INFO' ("{0} | {1} nhan / {2} luong | xung co ban {3} MHz" -f ([string]$cpu.Name).Trim(), $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors, $cpu.MaxClockSpeed)

$mods = @(Get-CimInstance Win32_PhysicalMemory)
foreach ($m in $mods) {
    $tn = Get-MemoryTypeName ([int]$m.SMBIOSMemoryType)
    Write-Status ("   Thanh RAM {0}" -f $m.DeviceLocator) 'INFO' ("{0}GB {1} {2}MHz (dang chay {3}MHz) | {4} {5}" -f [math]::Round($m.Capacity / 1GB, 0), $tn, $m.Speed, $m.ConfiguredClockSpeed, ([string]$m.Manufacturer).Trim(), ([string]$m.PartNumber).Trim())
}
$ra = Get-RamAssessment -Modules $mods
Write-Status 'RAM - dung luong' $ra.CapLevel $ra.CapDetail
Write-Status 'RAM - so kenh' $ra.ChanLevel $ra.ChanDetail
$slotCount = (Get-CimInstance Win32_PhysicalMemoryArray | Measure-Object -Property MemoryDevices -Sum).Sum
if (-not $ra.Soldered) {
    Write-Hint ("Windows bao {0} khe RAM - con so nay HAY SAI (dem ca RAM han). Muon chac: tra tai lieu hang theo model hoac mo nap day may." -f $slotCount)
}

# ----------------------------------------------------------------------------
Section '5. MAN HINH / CARD DO HOA'
# ----------------------------------------------------------------------------
$vcs = @(Get-CimInstance Win32_VideoController)
foreach ($v in $vcs) {
    $cur = if ($v.CurrentHorizontalResolution) { " | dang hien {0}x{1} @{2}Hz" -f $v.CurrentHorizontalResolution, $v.CurrentVerticalResolution, $v.CurrentRefreshRate } else { '' }
    Write-Status 'GPU' 'INFO' ("{0} | driver {1}{2}" -f $v.Name, $v.DriverVersion, $cur)
}

$monIds = @(Get-CimInstance -Namespace 'root/wmi' -ClassName WmiMonitorID -ErrorAction SilentlyContinue)
$monConn = @(Get-CimInstance -Namespace 'root/wmi' -ClassName WmiMonitorConnectionParams -ErrorAction SilentlyContinue)
$monModes = @(Get-CimInstance -Namespace 'root/wmi' -ClassName WmiMonitorListedSupportedSourceModes -ErrorAction SilentlyContinue)
$monBasic = @(Get-CimInstance -Namespace 'root/wmi' -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue)
$panelsChecked = 0
foreach ($mi in $monIds) {
    $inst = $mi.InstanceName
    $mk = ConvertFrom-WmiCharArray $mi.ManufacturerName
    $pc = ConvertFrom-WmiCharArray $mi.ProductCodeID
    $fn = ConvertFrom-WmiCharArray $mi.UserFriendlyName
    $conn = $monConn | Where-Object { $_.InstanceName -eq $inst } | Select-Object -First 1
    $isInternal = if ($conn) { Test-InternalPanel ([int64]$conn.VideoOutputTechnology) } else { $monIds.Count -eq 1 }

    $w = 0; $h = 0
    $md = $monModes | Where-Object { $_.InstanceName -eq $inst } | Select-Object -First 1
    if ($md -and $md.MonitorSourceModes) {
        $list = @($md.MonitorSourceModes)
        $idx = [int]$md.PreferredMonitorSourceModeIndex
        if ($idx -ge 0 -and $idx -lt $list.Count) {
            $w = [int]$list[$idx].HorizontalActivePixels; $h = [int]$list[$idx].VerticalActivePixels
        }
        if ($w -le 0) {
            $best = $list | Sort-Object { [int]$_.HorizontalActivePixels * [int]$_.VerticalActivePixels } -Descending | Select-Object -First 1
            $w = [int]$best.HorizontalActivePixels; $h = [int]$best.VerticalActivePixels
        }
    }
    $inch = ''
    $bp = $monBasic | Where-Object { $_.InstanceName -eq $inst } | Select-Object -First 1
    if ($bp -and $bp.MaxHorizontalImageSize -gt 0) {
        $inch = " | ~{0} inch" -f [math]::Round([math]::Sqrt([math]::Pow($bp.MaxHorizontalImageSize, 2) + [math]::Pow($bp.MaxVerticalImageSize, 2)) / 2.54, 1)
    }
    $kind = if ($isInternal) { 'man LAPTOP' } else { 'man NGOAI' }
    Write-Status ("Tam nen ({0})" -f $kind) 'INFO' ("Hang {0}, ma {1} {2}{3}" -f $mk, $pc, $fn, $inch)
    if ($isInternal) {
        $pa = Get-PanelAssessment -Width $w -Height $h
        Write-Status 'Do phan giai goc man laptop' $pa.Level $pa.Detail
        Write-Hint ("Google '{0} {1} panel' de biet tam nen IPS hay TN, do sang (nit), do phu mau." -f $mk, $pc)
        $panelsChecked++
    }
}
if ($panelsChecked -eq 0) {
    Write-Status 'Do phan giai goc man laptop' 'INFO' 'Khong doc duoc EDID - xem Settings > Display > Display resolution (dong co chu Recommended).'
}
Write-Hint "Mo 'screen-test.html' (F11) de soi diem chet, ho sang, o mau."

# ----------------------------------------------------------------------------
Section '6. KET NOI: WiFi / Bluetooth / LAN'
# ----------------------------------------------------------------------------
$net = @(Get-CimInstance Win32_NetworkAdapter -Filter 'PhysicalAdapter=True' | Where-Object { $_.Name -notmatch 'Virtual|VPN|Loopback|TAP' })
$wifi = @($net | Where-Object { $_.Name -match 'Wi-?Fi|Wireless|802\.11|WLAN' })
$lan = @($net | Where-Object { $_.Name -notmatch 'Wi-?Fi|Wireless|802\.11|WLAN|Bluetooth' -and $_.Name -match 'Ethernet|GbE|Gigabit|Family Controller|I21\d|I22\d|Realtek PCIe' })
$bt = @(Get-PnpDevice -Class Bluetooth -Status OK -ErrorAction SilentlyContinue)
if ($wifi.Count -gt 0) { Write-Status 'WiFi' 'PASS' ($wifi[0].Name) } else { Write-Status 'WiFi' 'WARN' 'Khong thay card WiFi (hong, bi thao hoac thieu driver).' }
if ($bt.Count -gt 0) { Write-Status 'Bluetooth' 'PASS' 'Co Bluetooth' } else { Write-Status 'Bluetooth' 'WARN' 'Khong thay Bluetooth (co the bi tat hoac thieu driver).' }
if ($lan.Count -gt 0) { Write-Status 'Cong mang LAN' 'INFO' ($lan[0].Name) }
Write-Hint 'Script chi thay CO card; van phai ket noi WiFi that va do tim tai nghe/dien thoai Bluetooth.'

# ----------------------------------------------------------------------------
Section '7. BAN QUYEN WINDOWS'
# ----------------------------------------------------------------------------
$lic = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL"
$activated = $lic | Where-Object { $_.LicenseStatus -eq 1 } | Select-Object -First 1
if ($activated) {
    Write-Status 'Kich hoat Windows' 'PASS' ("Da kich hoat ({0})" -f $activated.Description)
} else {
    Write-Status 'Kich hoat Windows' 'WARN' 'CHUA kich hoat - hoi nguoi ban.'
}
$sls = Get-CimInstance SoftwareLicensingService
if ($sls.OA3xOriginalProductKeyDescription) {
    Write-Status 'Key goc trong BIOS' 'INFO' ("Co: {0} - cai lai Windows dung phien ban nay se tu kich hoat." -f $sls.OA3xOriginalProductKeyDescription)
} else {
    Write-Status 'Key goc trong BIOS' 'INFO' 'Khong co (may doanh nghiep thuong dung key cong ty / KMS) - cai lai Windows co the mat ban quyen.'
}

# ----------------------------------------------------------------------------
Section '8. MAY DOANH NGHIEP / KHOA QUAN LY (quan trong voi Latitude, ThinkPad, EliteBook)'
# ----------------------------------------------------------------------------
if ($cs.PartOfDomain) {
    Write-Status 'Domain cong ty' 'WARN' ("May dang trong domain '{0}' - phai go ra va cai lai Windows." -f $cs.Domain)
} else {
    Write-Status 'Domain cong ty' 'PASS' 'Khong trong domain.'
}

$dsText = ''
$dsExe = Join-Path $env:windir 'System32\dsregcmd.exe'
if (Test-Path $dsExe) { $dsText = (& $dsExe /status 2>$null | Out-String) }
if ($dsText) {
    $aad = $dsText -match 'AzureAdJoined\s*:\s*YES'
    $ent = $dsText -match 'EnterpriseJoined\s*:\s*YES'
    $tenant = ''
    if ($dsText -match 'TenantName\s*:\s*(\S.*)') { $tenant = $Matches[1].Trim() }
    if ($aad -or $ent) {
        Write-Status 'Azure AD / Entra ID' 'WARN' ("May dang gan vao to chuc '{0}' - van bi cong ty quan ly. Yeu cau go va cai lai." -f $tenant)
    } else {
        Write-Status 'Azure AD / Entra ID' 'PASS' 'Khong gan vao to chuc nao.'
    }
}

$enr = @(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -ne 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' } |
    ForEach-Object { Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue } |
    Where-Object { $_.ProviderID -and ([string]$_.ProviderID).Trim() -ne '' })
if ($enr.Count -gt 0) {
    $desc = ($enr | ForEach-Object { "{0} {1}" -f $_.ProviderID, $_.UPN }) -join '; '
    Write-Status 'Quan ly MDM (Intune...)' 'WARN' ("Nghi con dang ky quan ly thiet bi: {0}. Xem Settings > Accounts > Access work or school." -f $desc)
} else {
    Write-Status 'Quan ly MDM (Intune...)' 'PASS' 'Khong thay dang ky MDM.'
}

$ap = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\Autopilot' -ErrorAction SilentlyContinue
$apTenant = if ($ap) { [string]$ap.CloudAssignedTenantDomain } else { '' }
if ($apTenant) {
    Write-Status 'Windows Autopilot' 'FAIL' ("May DANG DANG KY Autopilot cua '{0}': cai lai Windows co mang se bi bat dang nhap tai khoan cong ty. Chi mua khi nguoi ban chung minh da go." -f $apTenant)
} else {
    Write-Status 'Windows Autopilot' 'INFO' 'Khong thay dau vet Autopilot (chua chung minh tuyet doi - xem them luc cai lai Windows co mang).'
}

$pwInfo = Get-BiosPasswordInfo -Maker $maker
if ($pwInfo.Readable) {
    if ($pwInfo.SetNames.Count -gt 0) {
        Write-Status 'Mat khau BIOS' 'FAIL' ("DANG DAT mat khau: {0}. Nguoi ban phai go truoc mat ban - mat khau BIOS doanh nghiep rat kho pha." -f ($pwInfo.SetNames -join ', '))
    } else {
        Write-Status 'Mat khau BIOS' 'PASS' 'Khong dat mat khau BIOS.'
    }
} else {
    Write-Status 'Mat khau BIOS' 'INFO' 'Khong doc duoc tu Windows. Khoi dong lai, bam F2 (Dell) / F1 (Lenovo) / F10 (HP) / Del: phai vao BIOS ma KHONG bi hoi mat khau.'
}

$ctSvc = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(rpcnet|rpcnetp|CTES|Absolute)' })
$ctFile = @(@("$env:windir\System32\rpcnet.exe", "$env:windir\SysWOW64\rpcnet.exe", "$env:windir\System32\rpcnetp.exe") | Where-Object { Test-Path $_ })
if ($ctSvc.Count -gt 0 -or $ctFile.Count -gt 0) {
    Write-Status 'Computrace / Absolute' 'WARN' 'Thay phan mem chong trom Absolute dang chay: may co the van bi cong ty theo doi/khoa tu xa. Hoi nguoi ban hoac tranh.'
} else {
    Write-Status 'Computrace / Absolute' 'PASS' 'Khong thay agent trong Windows.'
}
Write-Hint 'Trong BIOS (Security > Absolute/Computrace) nen la "Disabled" hoac "Deactivate". "Activated/Enabled" = con bi theo doi.'

$blC = Get-CimInstance -Namespace 'root/cimv2/Security/MicrosoftVolumeEncryption' -ClassName Win32_EncryptableVolume -Filter "DriveLetter='C:'" -ErrorAction SilentlyContinue
if ($blC) {
    if ([int]$blC.ProtectionStatus -eq 1) {
        Write-Status 'BitLocker o C:' 'WARN' 'Dang ma hoa. Yeu cau nguoi ban TAT BitLocker (hoac cai lai Windows) truoc khi giao: neu khong, luc reset/doi main se bi hoi recovery key nam trong tai khoan cua ho.'
    } else {
        Write-Status 'BitLocker o C:' 'PASS' 'Khong ma hoa.'
    }
} elseif ($isAdmin) {
    Write-Status 'BitLocker o C:' 'INFO' 'Khong doc duoc (ban Windows Home khong co BitLocker day du).'
}

# ----------------------------------------------------------------------------
Section '9. LOI AN: Device Manager + nhat ky Windows'
# ----------------------------------------------------------------------------
$pnpBad = @(Get-CimInstance Win32_PnPEntity -Filter 'ConfigManagerErrorCode <> 0' -ErrorAction SilentlyContinue)
$pnpDisabled = @($pnpBad | Where-Object { [int]$_.ConfigManagerErrorCode -eq 22 })
$pnpBroken = @($pnpBad | Where-Object { [int]$_.ConfigManagerErrorCode -notin 22, 45 })
if ($pnpBroken.Count -gt 0) {
    $names = ($pnpBroken | Select-Object -First 8 | ForEach-Object {
            $nm = if ($_.Name) { $_.Name } else { $_.DeviceID }
            "{0} (ma {1})" -f $nm, $_.ConfigManagerErrorCode }) -join '; '
    Write-Status 'Thiet bi loi' 'WARN' ("{0} thiet bi loi/thieu driver: {1}" -f $pnpBroken.Count, $names)
    Write-Hint 'Ma 28 = thieu driver (cai la xong). Ma 10/43 = thiet bi khong chay/bao loi phan cung (webcam, van tay, card...) - can xem ky.'
} else {
    Write-Status 'Thiet bi loi' 'PASS' 'Device Manager khong co thiet bi loi.'
}
if ($pnpDisabled.Count -gt 0) {
    Write-Status 'Thiet bi bi tat' 'INFO' (($pnpDisabled | Select-Object -First 6 | ForEach-Object { $_.Name }) -join '; ')
}

$since = (Get-Date).AddDays(-90)
if ($installDate -and $installDate -gt $since) { $since = $installDate }
$days = [int]((Get-Date) - $since).TotalDays
Add-Line ("  (Nhat ky trong {0} ngay gan nhat)" -f $days)

$kp41 = Get-EventCount -Provider 'Microsoft-Windows-Kernel-Power' -Id 41 -Since $since
if ($kp41 -ge 3) { Write-Status 'Sap nguon dot ngot' 'WARN' ("{0} lan (Kernel-Power 41) - nghi pin/nguon/qua nhiet, hoac nguoi dung hay giu nut nguon tat may." -f $kp41) }
elseif ($kp41 -gt 0) { Write-Status 'Sap nguon dot ngot' 'INFO' ("{0} lan - it, co the do tat nguong cuong buc." -f $kp41) }
else { Write-Status 'Sap nguon dot ngot' 'PASS' 'Khong co.' }

$bsod = Get-EventCount -Provider 'Microsoft-Windows-WER-SystemErrorReporting', 'BugCheck' -Id 1001 -Since $since
if ($bsod -gt 0) { Write-Status 'Man hinh xanh (BSOD)' 'WARN' ("{0} lan - hoi nguoi ban; neu lap lai thuong do RAM/o cung/driver." -f $bsod) }
else { Write-Status 'Man hinh xanh (BSOD)' 'PASS' 'Khong co.' }

$whea = Get-EventCount -Provider 'Microsoft-Windows-WHEA-Logger' -Level 1, 2 -Since $since
if ($whea -gt 0) { Write-Status 'Loi phan cung (WHEA)' 'WARN' ("{0} loi phan cung nghiem trong duoc ghi nhan (CPU/RAM/PCIe)." -f $whea) }
else { Write-Status 'Loi phan cung (WHEA)' 'PASS' 'Khong co loi nghiem trong.' }

$diskErr = (Get-EventCount -Provider 'disk' -Id 7, 51, 153 -Since $since) + (Get-EventCount -Provider 'Ntfs', 'Microsoft-Windows-Ntfs' -Id 55 -Since $since)
if ($diskErr -gt 0) { Write-Status 'Loi o dia trong nhat ky' 'WARN' ("{0} su kien (bad block / I-O retry / hong file he thong). Co the do USB/the nho tung cam - doi chieu CrystalDiskInfo." -f $diskErr) }
else { Write-Status 'Loi o dia trong nhat ky' 'PASS' 'Khong co.' }

# ----------------------------------------------------------------------------
Section '10. TEST TAI CPU (phat hien tut xung do nong)'
# ----------------------------------------------------------------------------
if ($NoStress) {
    Write-Status 'Test tai CPU' 'INFO' 'Da bo qua (-NoStress).'
} else {
    if ($onBattery) { Write-Hint 'May dang chay PIN - ket qua se thap hon thuc te. Nen cam sac roi chay lai.' }
    Write-Host ("  Dang ep CPU 100% trong {0} giay - quat quay to la binh thuong, dung tat may..." -f $StressSeconds) -ForegroundColor DarkYellow
    $st = Invoke-CpuStress -Seconds $StressSeconds
    $ta = Get-ThrottleAssessment -Samples $st.Samples -OnBattery $onBattery
    $mhz = ''
    if ($st.NominalMHz -gt 0 -and $ta.Sustained -gt 0) {
        $mhz = " (~{0} MHz -> ~{1} MHz)" -f [math]::Round($st.NominalMHz * $ta.Peak / 100), [math]::Round($st.NominalMHz * $ta.Sustained / 100)
    }
    Write-Status 'Xung CPU khi tai nang' $ta.Level ($ta.Detail + $mhz)
    Write-Hint 'Muon soi nhiet do chinh xac: mo HWiNFO64 (Sensors) trong luc chay HeavyLoad 5 phut - xem TOOLS.md.'
}

# ============================================================================
Section 'TONG KET'
# ============================================================================
$verdict = Get-Verdict -Summary $script:Summary
$passCount = @($script:Summary | Where-Object { $_.Level -eq 'PASS' }).Count
Add-Line ("  TOT: {0}   |   CANH BAO: {1}   |   KEM: {2}" -f $passCount, $verdict.Warn, $verdict.Fail)
Add-Line ''
$vColor = switch ($verdict.Level) { 'FAIL' { 'Red' } 'WARN' { 'Yellow' } default { 'Green' } }
Write-Host ("  => {0}" -f $verdict.Text) -ForegroundColor $vColor
$script:Report.Add("  => " + $verdict.Text) | Out-Null
$issues = @($script:Summary | Where-Object { $_.Level -in 'FAIL', 'WARN' })
if ($issues.Count -gt 0) {
    Add-Line ''
    Add-Line '  CAN HOI NGUOI BAN / DUNG DE TRA GIA:'
    foreach ($it in $issues) { Add-Line ("   - [{0}] {1}: {2}" -f $it.Level, $it.Label, $it.Detail) }
}
Add-Line ''
Add-Line '  LUU Y: Van PHAI test tay theo CHECKLIST.md: man hinh (screen-test.html),'
Add-Line '  ban phim (keyboard-test.html), loa/mic/webcam (media-test.html), cong cam, ban le, pin phong.'

$txt = Join-Path $outDir 'BaoCao.txt'
$script:Report -join "`r`n" | Out-File -FilePath $txt -Encoding UTF8
$html = Join-Path $outDir 'BaoCao.html'
$meta = @{ Model = ("{0} {1}" -f $maker, $model); Serial = $serial; Time = (Get-Date -Format 'yyyy-MM-dd HH:mm') }
ConvertTo-HtmlReport -Summary $script:Summary.ToArray() -Meta $meta | Out-File -FilePath $html -Encoding UTF8

Write-Host ''
Write-Host ("Bao cao da luu tai: {0}" -f $outDir) -ForegroundColor Cyan
Write-Host '  BaoCao.html (de doc nhat) | BaoCao.txt | BatteryReport.html' -ForegroundColor Cyan
try { Start-Process $html } catch { try { Start-Process $outDir } catch {} }

Write-Host ''
Write-Host 'Nhan Enter de dong...' -ForegroundColor DarkGray
[void](Read-Host)
