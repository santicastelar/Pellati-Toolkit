# Detectar ruta base del proyecto
if ($PSScriptRoot) {
    $BasePath = $PSScriptRoot
}
else {
    $BasePath = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

$ModulesPath = Join-Path $BasePath "src"
$ToolsPath   = Join-Path $BasePath "tools"
$AssetsPath  = Join-Path $BasePath "assets"

. "$ModulesPath\Energia.ps1"
. "$ModulesPath\Sistema.ps1"
. "$ModulesPath\Diagnostico.ps1"
. "$ModulesPath\Software.ps1"
. "$ModulesPath\Red.ps1"
. "$ModulesPath\CarpetasWindows.ps1"
. "$ModulesPath\Disco.ps1"
. "$ModulesPath\Programas.ps1"
. "$ModulesPath\Office.ps1"
. "$ModulesPath\Herramientas.ps1"
. "$ModulesPath\Backup.ps1"

# Cargar librerías gráficas
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

[System.Windows.Forms.Application]::EnableVisualStyles()
# Ventana principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "Pellati-Toolkit"
$form.ClientSize = New-Object System.Drawing.Size(460, 680)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

# Titulo
$title = New-Object System.Windows.Forms.Label
$title.Text = "Pellati-Toolkit"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(95,20)
$form.Controls.Add($title)

# Subtitulo
$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Herramientas de soporte y post-instalacion"
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(65,60)
$form.Controls.Add($subtitle)

# Funcion para crear botones
function Crear-Boton {
    param(
        [string]$Texto,
        [int]$Y,
        [scriptblock]$Accion
    )

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Texto
    $btn.Size = New-Object System.Drawing.Size(340,36)

    $x = [int](($form.ClientSize.Width - $btn.Width) / 2)
    $btn.Location = New-Object System.Drawing.Point($x, $Y)

    $btn.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $btn.Add_Click($Accion)

    $form.Controls.Add($btn)
}

# Botones

Crear-Boton "Sistema" 100 {
    Mostrar-Sistema
}

Crear-Boton "Backup" 145 {
    Mostrar-Backup
}

Crear-Boton "Energía" 190 {
    Mostrar-Energia
}

Crear-Boton "Programas" 235 {
    Mostrar-Programas
}

Crear-Boton "Disco" 280 {
    Mostrar-Disco
}

Crear-Boton "Carpetas de Windows" 325 {
    Mostrar-CarpetasWindows
}

Crear-Boton "Herramientas" 370 {
    Mostrar-Herramientas
}

Crear-Boton "Office" 415 {
    Mostrar-Office
}

[void]$form.ShowDialog()


