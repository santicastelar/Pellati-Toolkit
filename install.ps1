$ErrorActionPreference = "Stop"

$Repositorio = "santicastelar/Pellati-Toolkit"

$InstallPath = "$env:USERPROFILE\Desktop\Pellati-Toolkit"
$ZipPath = Join-Path $env:TEMP "Pellati-Toolkit.zip"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "     Descargandoo Pellati-Toolkit" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Obtener la última Release desde GitHub
Write-Host "[1/4] Buscando la última versión..." -ForegroundColor Yellow

$Release = Invoke-RestMethod "https://api.github.com/repos/$Repositorio/releases/latest"

$Asset = $Release.assets | Where-Object {
    $_.name -like "*.zip" -and $_.name -notlike "*Source*"
} | Select-Object -First 1

if (-not $Asset) {
    throw "No se encontró ningún archivo ZIP en la última Release."
}

# Crear carpeta de instalación
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath | Out-Null
}

# Descargar
Write-Host "[2/4] Descargando $($Asset.name)..." -ForegroundColor Yellow

Invoke-WebRequest `
    -Uri $Asset.browser_download_url `
    -OutFile $ZipPath

# Extraer
Write-Host "[3/4] Extrayendo archivos..." -ForegroundColor Yellow

Expand-Archive `
    -Path $ZipPath `
    -DestinationPath $InstallPath `
    -Force

# Buscar el ejecutable
$Exe = Get-ChildItem `
    -Path $InstallPath `
    -Recurse `
    -Filter "Pellati-Toolkit.exe" |
    Select-Object -First 1

if (-not $Exe) {
    throw "No se encontró Pellati-Toolkit.exe."
}

# Ejecutar
Write-Host "[4/4] Iniciando Pellati-Toolkit..." -ForegroundColor Yellow

Start-Process $Exe.FullName -Verb RunAs

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " Instalación completada correctamente." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green