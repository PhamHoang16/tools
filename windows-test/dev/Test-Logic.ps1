<#
  Test-Logic.ps1 - kiem tra cac ham danh gia trong Test-LaptopCu.ps1.
  Khong can Windows: chay duoc bang pwsh tren Linux/macOS hoac Windows PowerShell 5.1.
      pwsh -NoProfile -File dev/Test-Logic.ps1
  Thoat ma 1 neu co test sai.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Test-LaptopCu.ps1')

$script:failed = 0
$script:passed = 0
function Assert-Equal {
    param($Actual, $Expected, [string]$Name)
    if ("$Actual" -ceq "$Expected") { $script:passed++ }
    else { $script:failed++; Write-Host ("FAIL  {0}: mong '{1}', nhan '{2}'" -f $Name, $Expected, $Actual) -ForegroundColor Red }
}
function New-Mod { param([double]$GB, [int]$Type = 26) [pscustomobject]@{ Capacity = $GB * 1GB; SMBIOSMemoryType = $Type } }

# --- RAM: tinh tu dung luong thanh, KHONG tu TotalPhysicalMemory (ban cu bao 8GB thanh CANH BAO) ---
$r = Get-RamAssessment -Modules @(New-Mod 8)
Assert-Equal $r.TotalGB 8 'RAM 1x8 tong'
Assert-Equal $r.CapLevel 'INFO' 'RAM 1x8 dung luong khong bi canh bao'
Assert-Equal $r.ChanLevel 'WARN' 'RAM 1x8 -> single-channel'
$r = Get-RamAssessment -Modules @((New-Mod 8), (New-Mod 8))
Assert-Equal $r.CapLevel 'PASS' 'RAM 2x8 dung luong'
Assert-Equal $r.ChanLevel 'PASS' 'RAM 2x8 dual-channel'
$r = Get-RamAssessment -Modules @((New-Mod 8), (New-Mod 4))
Assert-Equal $r.TotalGB 12 'RAM 8+4 tong'
Assert-Equal $r.ChanLevel 'WARN' 'RAM 8+4 lech dung luong'
$r = Get-RamAssessment -Modules @(1..8 | ForEach-Object { New-Mod 2 35 })
Assert-Equal $r.Soldered $true 'LPDDR5 la RAM han'
Assert-Equal $r.ChanLevel 'INFO' 'LPDDR5 khong khuyen lap them thanh'
Assert-Equal $r.TotalGB 16 'LPDDR5 8x2GB tong'
$r = Get-RamAssessment -Modules @((New-Mod 4))
Assert-Equal $r.CapLevel 'WARN' 'RAM 4GB it'
$r = Get-RamAssessment -Modules @()
Assert-Equal $r.CapLevel 'WARN' 'RAM khong doc duoc'

# --- Pin ---
Assert-Equal (Get-BatteryAssessment -Design 54000 -Full 50000).Level 'PASS' 'Pin 92%'
Assert-Equal (Get-BatteryAssessment -Design 54000 -Full 40000).Level 'WARN' 'Pin 74%'
Assert-Equal (Get-BatteryAssessment -Design 54000 -Full 30000).Level 'FAIL' 'Pin 55%'
Assert-Equal (Get-BatteryAssessment -Design 54000 -Full 60000).Level 'WARN' 'Pin 111% la nghi pin lo (ban cu cham TOT)'
Assert-Equal (Get-BatteryAssessment -Design 54000 -Full 55000).Level 'PASS' 'Pin 101.9% van coi la binh thuong'
Assert-Equal (Get-BatteryAssessment -Design 0 -Full 0).Level 'WARN' 'Pin khong doc duoc'
Assert-Equal (Get-CycleLevel 120) 'PASS' 'Cycle 120'
Assert-Equal (Get-CycleLevel 900) 'FAIL' 'Cycle 900'

# --- O cung: Unknown khong duoc cham KEM (ban cu cham FAIL) ---
Assert-Equal (Get-DiskHealthLevel 'Healthy') 'PASS' 'Disk Healthy'
Assert-Equal (Get-DiskHealthLevel 'Warning') 'WARN' 'Disk Warning'
Assert-Equal (Get-DiskHealthLevel 'Unhealthy') 'FAIL' 'Disk Unhealthy'
Assert-Equal (Get-DiskHealthLevel 'Unknown') 'WARN' 'Disk Unknown -> WARN'
Assert-Equal (Get-DiskHealthLevel '') 'WARN' 'Disk rong -> WARN'

# --- Serial ---
Assert-Equal (Test-PlaceholderSerial 'To be filled by O.E.M.') $true 'Serial OEM'
Assert-Equal (Test-PlaceholderSerial 'Default string') $true 'Serial default'
Assert-Equal (Test-PlaceholderSerial '  ') $true 'Serial rong'
Assert-Equal (Test-PlaceholderSerial '0000000') $true 'Serial toan so 0'
Assert-Equal (Test-PlaceholderSerial 'HX2K9Q3') $false 'Service tag Dell that'
Assert-Equal (Test-PlaceholderSerial 'PF2ABCDE') $false 'Serial Lenovo that'
Assert-Equal (Get-WarrantyUrl 'Dell Inc.' 'HX2K9Q3') 'https://www.dell.com/support/home/en-us/product-support/servicetag/HX2K9Q3/overview' 'URL Dell'
Assert-Equal (Get-WarrantyUrl 'Dell Inc.' 'Default string') '' 'Khong tao URL cho serial gia'

# --- Man hinh ---
Assert-Equal (ConvertFrom-WmiCharArray @(66, 79, 69, 0, 0)) 'BOE' 'EDID ten hang'
Assert-Equal (Get-PanelAssessment -Width 1366 -Height 768).Level 'WARN' 'Man HD'
Assert-Equal (Get-PanelAssessment -Width 1920 -Height 1080).Level 'PASS' 'Man FHD'
Assert-Equal (Get-PanelAssessment -Width 0 -Height 0).Level 'INFO' 'Man khong doc duoc'
Assert-Equal (Test-InternalPanel 11) $true 'eDP la man trong'
Assert-Equal (Test-InternalPanel 2147483648) $true 'INTERNAL 0x80000000'
Assert-Equal (Test-InternalPanel 5) $false 'HDMI la man ngoai'

# --- Xung CPU ---
$t = Get-ThrottleAssessment -Samples @(130, 125, 118, 105, 100, 98, 97) -OnBattery $false
Assert-Equal $t.Level 'PASS' 'Tut tu dinh ve ~100% la binh thuong'
$t = Get-ThrottleAssessment -Samples @(120, 90, 60, 45, 40, 42, 41) -OnBattery $false
Assert-Equal $t.Level 'WARN' 'Duy tri 41% la tut xung manh'
Assert-Equal $t.Sustained 41 'Trung binh 3 mau cuoi'
$t = Get-ThrottleAssessment -Samples @(120, 90, 60, 45, 40, 42, 41) -OnBattery $true
Assert-Equal $t.Level 'INFO' 'Chay pin thi khong ket luan'
$t = Get-ThrottleAssessment -Samples @(0, 0, 100) -OnBattery $false
Assert-Equal $t.Level 'INFO' 'It mau -> khong ket luan'

# --- Ket luan + HTML ---
$sum = @(
    [pscustomobject]@{ Section = 'A'; Label = 'x'; Level = 'PASS'; Detail = 'ok' },
    [pscustomobject]@{ Section = 'A'; Label = 'y'; Level = 'WARN'; Detail = '<script>alert(1)</script> https://example.com/a?b=1&c=2' }
)
Assert-Equal (Get-Verdict $sum).Level 'WARN' 'Verdict co WARN'
Assert-Equal (Get-Verdict ($sum + [pscustomobject]@{ Section = 'B'; Label = 'z'; Level = 'FAIL'; Detail = 'x' })).Level 'FAIL' 'Verdict co FAIL'
Assert-Equal (Get-Verdict @([pscustomobject]@{ Section = 'A'; Label = 'x'; Level = 'INFO'; Detail = '' })).Level 'PASS' 'Verdict chi INFO'
$h = ConvertTo-HtmlReport -Summary $sum -Meta @{ Model = 'Dell <Latitude>'; Serial = 'ABC'; Time = 'now' }
Assert-Equal ($h -match '<script>alert') $false 'HTML escape noi dung'
Assert-Equal ($h -match '&lt;script&gt;') $true 'HTML giu noi dung da escape'
Assert-Equal ($h -match '<a href="https://example.com/a\?b=1&amp;c=2"') $true 'HTML bien URL thanh link'
Assert-Equal ($h -match 'Dell &lt;Latitude&gt;') $true 'HTML escape model'

Write-Host ("{0} dung, {1} sai" -f $script:passed, $script:failed) -ForegroundColor $(if ($script:failed) { 'Red' } else { 'Green' })
if ($script:failed) { exit 1 }
