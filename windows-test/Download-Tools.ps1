<#
================================================================================
  Download-Tools.ps1 - Tai san phan mem portable de test laptop cu
--------------------------------------------------------------------------------
  CHAY O NHA (noi co mang). Script tai cac tool portable ve thu muc
  "PortableTools" canh ben. Sau do copy ca thu muc windows-test vao USB,
  ra tiem cam chay offline (khong can cai dat, khong can mang).

  Chay:  click phai -> Run with PowerShell
     hoac: powershell -ExecutionPolicy Bypass -File .\Download-Tools.ps1
================================================================================
#>
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dest = Join-Path $PSScriptRoot 'PortableTools'
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Write-Host "Tai ve: $dest`n" -ForegroundColor Cyan

# Danh sach tool: ten | URL (link 'latest' kha on dinh cua SourceForge) | ten file
$tools = @(
    @{ Name='CrystalDiskInfo'; Url='https://sourceforge.net/projects/crystaldiskinfo/files/latest/download'; File='CrystalDiskInfo.zip' },
    @{ Name='CrystalDiskMark'; Url='https://sourceforge.net/projects/crystaldiskmark/files/latest/download'; File='CrystalDiskMark.zip' }
)

# HWiNFO portable: link co phien ban thay doi -> thu winget truoc, that bai thi bao link tay.
function Get-File($name, $url, $file) {
    $out = Join-Path $dest $file
    Write-Host ("-> Dang tai {0} ..." -f $name) -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 120
        $kb = [math]::Round((Get-Item $out).Length/1KB)
        Write-Host ("   OK: {0} ({1} KB)" -f $file, $kb) -ForegroundColor Green
        # Tu giai nen neu la .zip
        if ($file -like '*.zip') {
            $ex = Join-Path $dest ($file -replace '\.zip$','')
            try { Expand-Archive -Path $out -DestinationPath $ex -Force; Write-Host "   Da giai nen -> $ex" -ForegroundColor DarkGreen } catch {}
        }
    } catch {
        Write-Host ("   LOI tai {0}. Tai tay tai: {1}" -f $name, $url) -ForegroundColor Red
    }
}

foreach ($t in $tools) { Get-File $t.Name $t.Url $t.File }

# --- HWiNFO + HeavyLoad: thu winget (co san tren Win 10/11) ---
Write-Host "`n-> Thu tai HWiNFO & HeavyLoad qua winget (neu co)..." -ForegroundColor Yellow
if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget download --id REALiX.HWiNFO --download-directory "$dest" 2>$null
    Write-Host "   (Neu winget khong tai duoc ban portable, vao link tay ben duoi)" -ForegroundColor DarkGray
} else {
    Write-Host "   Khong co winget." -ForegroundColor DarkGray
}

Write-Host "`n=============================================================" -ForegroundColor Cyan
Write-Host "Link tai tay (neu tool nao bi loi o tren):" -ForegroundColor Cyan
Write-Host "  HWiNFO portable : https://www.hwinfo.com/download/"
Write-Host "  HeavyLoad       : https://www.jam-software.com/heavyload"
Write-Host "  CrystalDiskInfo : https://crystalmark.info/en/software/"
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "`nXong. Copy ca thu muc 'windows-test' (kem PortableTools) vao USB." -ForegroundColor Green
try { Start-Process $dest } catch {}
Write-Host "`nNhan Enter de dong..."; [void](Read-Host)
