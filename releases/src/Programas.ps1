function Abrir-Lightshot {

    $ruta = Join-Path $PSScriptRoot "..\tools\LightshotPortable\LightshotPortable.exe"

    if (Test-Path $ruta) {
        Start-Process $ruta
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró Lightshot Portable en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Instalar-LightShot {

    $ruta = Join-Path $PSScriptRoot "..\tools\Lightshot\lightshot.exe"

    if (Test-Path $ruta) {
        Start-Process $ruta
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró el instalador de LightShot en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Abrir-TeamViewer12 {

    $ruta = Join-Path $PSScriptRoot "..\tools\TeamViewer_Setup12\TeamViewer_Setup12.exe"

    if (Test-Path $ruta) {
        Start-Process $ruta
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró TeamViewer 12 en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Abrir-AnyDesk {

    $ruta = Join-Path $PSScriptRoot "..\tools\Anydesk\AnyDesk.exe"

    if (Test-Path $ruta) {
        Start-Process $ruta
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró AnyDesk en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Reset-AnyDesk {

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
Esta función reiniciará la configuración de AnyDesk.

Utilice esta opción cuando necesite generar un nuevo ID o solucionar problemas de conexión.

Los archivos de configuración actuales serán respaldados automáticamente.

¿Desea continuar?
"@,
        "Reset AnyDesk",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    try {
        Get-Process AnyDesk -ErrorAction SilentlyContinue | Stop-Process -Force

        $configPath = "C:\ProgramData\AnyDesk"

        if (Test-Path "$configPath\system.conf.backup") {
            Remove-Item "$configPath\system.conf.backup" -Force
        }

        if (Test-Path "$configPath\service.conf.backup") {
            Remove-Item "$configPath\service.conf.backup" -Force
        }

        if (Test-Path "$configPath\system.conf") {
            Rename-Item "$configPath\system.conf" "system.conf.backup"
        }

        if (Test-Path "$configPath\service.conf") {
            Rename-Item "$configPath\service.conf" "service.conf.backup"
        }

        $anydeskExe = "C:\Program Files (x86)\AnyDesk\AnyDesk.exe"

        if (Test-Path $anydeskExe) {
            Start-Process $anydeskExe
        }

        [System.Windows.Forms.MessageBox]::Show(
            "AnyDesk fue reiniciado correctamente.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Ocurrió un error al reiniciar AnyDesk.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Abrir-EverythingPortable {

    $basePath = Join-Path $PSScriptRoot "..\tools\Everything"

    if ([Environment]::Is64BitOperatingSystem) {
        $ruta = Join-Path $basePath "Everything-1.4.1.1003.x64\Everything.exe"
    }
    else {
        $ruta = Join-Path $basePath "Everything-1.4.1.1003.x86\Everything.exe"
    }

    if (Test-Path $ruta) {
        Start-Process $ruta
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró Everything Portable en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Abrir-WinRAR {

    $ruta = Join-Path $PSScriptRoot "..\tools\WinRAR\winrar-x64-531.exe"

    if (Test-Path $ruta) {
        Start-Process $ruta
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró WinRAR en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Abrir-7Zip {

    $ruta = Join-Path $PSScriptRoot "..\tools\7Zip\7z2601-x64.exe"

    if (Test-Path $ruta) {
        Start-Process $ruta
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró 7-Zip en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
function Instalar-Chrome {

    $ruta = Join-Path $PSScriptRoot "..\tools\Chrome\ChromeSetup.exe"

    if (Test-Path $ruta) {
        Start-Process $ruta
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró Google Chrome en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
function Instalar-Firefox {

    $ruta = Join-Path $PSScriptRoot "..\tools\Firefox\Firefox Installer.exe"

    if (Test-Path $ruta) {
        Start-Process $ruta
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró Firefox en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
function Mostrar-Programas {

    $formProgramas = New-Object System.Windows.Forms.Form
    $formProgramas.Text = "Programas"
    $formProgramas.ClientSize = New-Object System.Drawing.Size(420,700)
    $formProgramas.StartPosition = "CenterScreen"
    $formProgramas.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonProgramas {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($formProgramas.ClientSize.Width - $btn.Width) / 2)
        $btn.Location = New-Object System.Drawing.Point($x,$Y)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $formProgramas.Controls.Add($btn)
    }
Crear-BotonProgramas "7-Zip" 40 {
    Abrir-7Zip
}

Crear-BotonProgramas "WinRAR" 95 {
    Abrir-WinRAR
}

Crear-BotonProgramas "Google Chrome" 150 {
    Instalar-Chrome
}

Crear-BotonProgramas "Firefox" 205 {
    Instalar-Firefox
}

Crear-BotonProgramas "TeamViewer 12" 260 {
    Abrir-TeamViewer12
}

Crear-BotonProgramas "AnyDesk" 315 {
    Abrir-AnyDesk
}

Crear-BotonProgramas "Reset AnyDesk" 370 {
    Reset-AnyDesk
}

Crear-BotonProgramas "Lightshot" 425 {
    Instalar-LightShot
}

Crear-BotonProgramas "Everything Portable" 480 {
    Abrir-EverythingPortable
}

Crear-BotonProgramas "Lightshot Portable" 535 {
    Abrir-Lightshot
}
    [void]$formProgramas.ShowDialog()
}