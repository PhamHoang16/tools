<#
================================================================================
  Download-Tools.ps1 - Tai san phan mem PORTABLE de test laptop cu
--------------------------------------------------------------------------------
  CHAY O NHA (noi co mang). Script tai cac tool portable ve thu muc
  "PortableTools" canh ben va giai nen san. Sau do copy ca thu muc windows-test
  vao USB, ra tiem cam chay offline - KHONG can cai gi len may nguoi ban.

  Chay:  click phai -> Run with PowerShell
     hoac: powershell -ExecutionPolicy Bypass -File .\Download-Tools.ps1

  Ghi chu: SourceForge tra ve trang HTML "cho 5 giay" neu nhan dien la trinh
  duyet/PowerShell, nen phai gia User-Agent 'Wget' moi nhan file that. Moi file
  tai ve deu duoc kiem tra la file ZIP that (bat dau bang 'PK') truoc khi bao OK.
================================================================================
#>
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # thanh tien do lam Invoke-WebRequest cham hang chuc lan tren PS 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dest = Join-Path $PSScriptRoot 'PortableTools'
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Write-Host "Tai ve: $dest`n" -ForegroundColor Cyan

# Ten | link 'latest' cua SourceForge (deu la ban ZIP portable) | trang chinh chu de tai tay
$tools = @(
    @{ Name = 'CrystalDiskInfo'; Url = 'https://sourceforge.net/projects/crystaldiskinfo/files/latest/download'; Home = 'https://crystalmark.info/en/software/crystaldiskinfo/' },
    @{ Name = 'CrystalDiskMark'; Url = 'https://sourceforge.net/projects/crystaldiskmark/files/latest/download'; Home = 'https://crystalmark.info/en/software/crystaldiskmark/' },
    @{ Name = 'HWiNFO64';        Url = 'https://sourceforge.net/projects/hwinfo/files/latest/download';          Home = 'https://www.hwinfo.com/download/ (chon ban Portable)' }
)

function Test-ZipFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    $fs = [System.IO.File]::OpenRead($Path)
    try {
        $buf = New-Object byte[] 2
        $read = $fs.Read($buf, 0, 2)
        return ($read -eq 2 -and $buf[0] -eq 0x50 -and $buf[1] -eq 0x4B)   # 'PK'
    } finally { $fs.Dispose() }
}

$ok = @(); $bad = @()
foreach ($t in $tools) {
    $zip = Join-Path $dest ($t.Name + '.zip')
    $dir = Join-Path $dest $t.Name
    Write-Host ("-> Dang tai {0} ..." -f $t.Name) -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $t.Url -OutFile $zip -UseBasicParsing -UserAgent 'Wget' -TimeoutSec 300
        if (-not (Test-ZipFile $zip)) { throw 'File tai ve khong phai ZIP (co the la trang HTML).' }
        if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
        Expand-Archive -Path $zip -DestinationPath $dir -Force
        Remove-Item $zip -Force
        $mb = [math]::Round(((Get-ChildItem $dir -Recurse | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
        Write-Host ("   OK: {0} ({1} MB) -> {2}" -f $t.Name, $mb, $dir) -ForegroundColor Green
        $ok += $t.Name
    } catch {
        Write-Host ("   LOI: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host ("   Tai tay tai: {0}" -f $t.Home) -ForegroundColor Red
        if (Test-Path $zip) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
        $bad += $t.Name
    }
}

Write-Host "`n=============================================================" -ForegroundColor Cyan
Write-Host ("Tai thanh cong: {0}" -f ($(if ($ok) { $ok -join ', ' } else { '(khong co)' }))) -ForegroundColor Green
if ($bad) { Write-Host ("Can tai tay   : {0}" -f ($bad -join ', ')) -ForegroundColor Red }
Write-Host ''
Write-Host 'Tuy chon, tai tay neu can:' -ForegroundColor Cyan
Write-Host '  HeavyLoad (ep tai CPU+GPU lau hon): https://www.jam-software.com/heavyload'
Write-Host '  -> Test-LaptopCu.ps1 da co san bai ep CPU 30 giay, thuong la du.'
Write-Host '=============================================================' -ForegroundColor Cyan
Write-Host "`nXong. Copy ca thu muc 'windows-test' (kem PortableTools) vao USB." -ForegroundColor Green
try { Start-Process $dest } catch {}
Write-Host "`nNhan Enter de dong..."; [void](Read-Host)
