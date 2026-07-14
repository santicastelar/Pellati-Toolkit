$ErrorActionPreference = "Stop"

$Repositorio = "santicastelar/Pellati-Toolkit"
$ZipPath = Join-Path $env:TEMP "Pellati-Toolkit.zip"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "     Descargando Pellati-Toolkit" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/5] Buscando la última versión..." -ForegroundColor Yellow

$Release = Invoke-RestMethod "https://api.github.com/repos/$Repositorio/releases/latest"

$Asset = $Release.assets | Where-Object {
    $_.name -like "*.zip" -and $_.name -notlike "*Source*"
} | Select-Object -First 1

if (-not $Asset) {
    throw "No se encontró ningún archivo ZIP en la última Release."
}

$InstallPath = Join-Path `
    ([Environment]::GetFolderPath("Desktop")) `
    "Pellati-Toolkit-$($Release.tag_name)"

if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath | Out-Null
}

Write-Host "[2/5] Descargando $($Asset.name)..." -ForegroundColor Yellow

Invoke-WebRequest `
    -Uri $Asset.browser_download_url `
    -OutFile $ZipPath

Write-Host "[3/5] Extrayendo archivos..." -ForegroundColor Yellow

Expand-Archive `
    -Path $ZipPath `
    -DestinationPath $InstallPath `
    -Force

Write-Host "[4/5] Desbloqueando archivos..." -ForegroundColor Yellow

Get-ChildItem `
    -Path $InstallPath `
    -Recurse `
    -File |
    Unblock-File -ErrorAction SilentlyContinue

$Exe = Get-ChildItem `
    -Path $InstallPath `
    -Recurse `
    -Filter "Pellati-Toolkit.exe" |
    Select-Object -First 1

if (-not $Exe) {
    throw "No se encontró Pellati-Toolkit.exe."
}

Write-Host "[5/5] Iniciando Pellati-Toolkit..." -ForegroundColor Yellow

Start-Process $Exe.FullName -Verb RunAs
Start-Process explorer.exe $InstallPath

Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " Pellati-Toolkit está listo para usar." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Ubicación:" -ForegroundColor Cyan
Write-Host $InstallPath
Write-Host ""