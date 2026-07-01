Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "        Pellati-Toolkit - Build" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$Proyecto = $PSScriptRoot
$Release = Join-Path $Proyecto "releases"

# Crear carpeta Releases si no existe
if (!(Test-Path $Release)) {
    New-Item -ItemType Directory -Path $Release | Out-Null
}

# Limpiar release anterior
Write-Host "[1/5] Limpiando carpeta releases..." -ForegroundColor Yellow

Get-ChildItem $Release -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Compilar
Write-Host "[2/5] Compilando Pellati-Toolkit..." -ForegroundColor Yellow

Invoke-PS2EXE `
    -InputFile "$Proyecto\PellatiToolkit.ps1" `
    -OutputFile "$Release\Pellati-Toolkit.exe" `
    -NoConsole `
    -RequireAdmin

# Copiar carpetas
Write-Host "[3/5] Copiando archivos..." -ForegroundColor Yellow

Copy-Item "$Proyecto\src" "$Release\" -Recurse -Force
Copy-Item "$Proyecto\tools" "$Release\" -Recurse -Force
Copy-Item "$Proyecto\assets" "$Release\" -Recurse -Force

# Copiar archivos
Write-Host "[4/5] Copiando documentación..." -ForegroundColor Yellow

Copy-Item "$Proyecto\README.md" "$Release\" -Force

# Finalizado
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " Build finalizado correctamente." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Salida:" -ForegroundColor Cyan
Write-Host "$Release"
Write-Host ""