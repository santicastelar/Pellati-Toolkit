function Abrir-NombreEquipo { Start-Process "sysdm.cpl" }
function Abrir-AcercaEquipo { Start-Process "control.exe" -ArgumentList "system" }
function Abrir-IconosEscritorio { Start-Process "rundll32.exe" -ArgumentList "shell32.dll,Control_RunDLL desk.cpl,,0" }
function Abrir-Taskmgr { taskmgr.exe }
function Abrir-OpcionesCarpeta { Start-Process "control.exe" -ArgumentList "folders" }
function Abrir-ProteccionSistema { Start-Process "SystemPropertiesProtection.exe" }
function Abrir-ProgramasInstalados { Start-Process "appwiz.cpl" }
function Abrir-AppsInicio { Start-Process "ms-settings:startupapps" }
function Abrir-AdministradorDispositivos { Start-Process "devmgmt.msc" }
function Abrir-Servicios { Start-Process "services.msc" }
function Abrir-EditarPlanEnergia { Start-Process "powercfg.cpl" }
function Abrir-CredencialesWindows { Start-Process "control.exe" -ArgumentList "/name Microsoft.CredentialManager" }

if (-not ("LogonHelper" -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class LogonHelper {
    [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern bool LogonUser(string u, string d, string p, int t, int pr, out IntPtr token);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CloseHandle(IntPtr h);
}
"@
}

function Probar-CredencialLocal {
    param([string]$Usuario,[string]$Dominio,[string]$Password)

    $token = [IntPtr]::Zero
    $ok = [LogonHelper]::LogonUser($Usuario,$Dominio,$Password,2,0,[ref]$token)

    if ($token -ne [IntPtr]::Zero) {
        [LogonHelper]::CloseHandle($token) | Out-Null
    }

    return $ok
}

function Pedir-PasswordUsuario {
    param([string]$UsuarioCompleto)

    $formPass = New-Object System.Windows.Forms.Form
    $formPass.Text = "Contraseña del usuario"
    $formPass.ClientSize = New-Object System.Drawing.Size(420,160)
    $formPass.StartPosition = "CenterScreen"
    $formPass.FormBorderStyle = "FixedDialog"
    $formPass.MaximizeBox = $false
    $formPass.MinimizeBox = $false

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Ingrese la contraseña de:`n$UsuarioCompleto"
    $lbl.AutoSize = $true
    $lbl.Location = New-Object System.Drawing.Point(25,20)
    $formPass.Controls.Add($lbl)

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Size = New-Object System.Drawing.Size(360,25)
    $txt.Location = New-Object System.Drawing.Point(25,70)
    $txt.UseSystemPasswordChar = $true
    $formPass.Controls.Add($txt)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Aceptar"
    $btnOk.Size = New-Object System.Drawing.Size(100,30)
    $btnOk.Location = New-Object System.Drawing.Point(175,110)
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $formPass.AcceptButton = $btnOk
    $formPass.Controls.Add($btnOk)

    if ($formPass.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $txt.Text
    }

    return $null
}

function Exportar-UsuarioActual {

    $usuario = $env:USERNAME
    $dominio = $env:USERDOMAIN
    $usuarioCompleto = "$dominio\$usuario"

    $BackupPath = Obtener-CarpetaBackup
    $ruta = Join-Path $BackupPath "Backup_Usuario.txt"

    if (Probar-CredencialLocal -Usuario $usuario -Dominio $dominio -Password "") {

        $contenido = @(
            "BACKUP USUARIO ACTUAL",
            "=====================",
            "",
            "Usuario: $usuarioCompleto",
            "Contraseña: La cuenta no contiene contraseña.",
            "",
            "Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        )

        $contenido | Out-File $ruta -Encoding UTF8

        [System.Windows.Forms.MessageBox]::Show(
            "Backup guardado en:`n$ruta`n`nLa cuenta no contiene contraseña.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        return
    }

    do {
        $password = Pedir-PasswordUsuario -UsuarioCompleto $usuarioCompleto

        if ($null -eq $password) {
            return
        }

        if ([string]::IsNullOrWhiteSpace($password)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Debe ingresar una contraseña para continuar.",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            continue
        }

        $esCorrecta = Probar-CredencialLocal -Usuario $usuario -Dominio $dominio -Password $password

        if (-not $esCorrecta) {
            [System.Windows.Forms.MessageBox]::Show(
                "La contraseña ingresada no es correcta. Intente nuevamente.",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }

    } until ($esCorrecta)

    $contenido = @(
        "BACKUP USUARIO ACTUAL",
        "=====================",
        "",
        "Usuario: $usuarioCompleto",
        "Contraseña: $password",
        "",
        "Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    )

    $contenido | Out-File $ruta -Encoding UTF8

    [System.Windows.Forms.MessageBox]::Show(
        "Backup guardado en:`n$ruta",
        "Pellati-Toolkit",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

function Exportar-NombreEquipo {

    $BackupPath = Obtener-CarpetaBackup

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
Se exportará la información en la carpeta:

$BackupPath

El backup incluirá:

- Nombre del equipo
- Dominio
- Grupo de trabajo

¿Desea continuar?
"@,
        "Backup nombre del equipo",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $ruta = Join-Path $BackupPath "NombreEquipo.txt"

    try {
        $cs = Get-CimInstance Win32_ComputerSystem

        $contenido = @()
        $contenido += "BACKUP NOMBRE DEL EQUIPO"
        $contenido += "========================"
        $contenido += ""
        $contenido += "Nombre del equipo: $($env:COMPUTERNAME)"

        if ($cs.PartOfDomain) {
            $contenido += "Dominio: $($cs.Domain)"
        }
        else {
            $contenido += "Grupo de trabajo: $($cs.Workgroup)"
        }

        $contenido | Out-File $ruta -Encoding UTF8

        [System.Windows.Forms.MessageBox]::Show(
            "Backup guardado en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo obtener la información del equipo.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Exportar-UnidadesMapeadas {

    $BackupPath = Obtener-CarpetaBackup

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
        "Se exportarán las unidades de red mapeadas en la carpeta:`n$BackupPath`n`n¿Desea continuar?",
        "Exportar unidades de red",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $ruta = Join-Path $BackupPath "UnidadesMapeadas.txt"
    $contenido = @()

    $contenido += "UNIDADES MAPEADAS - NET USE"
    $contenido += "============================"
    $contenido += (net use)
    $contenido += ""
    $contenido += "UNIDADES PERSISTENTES - REGISTRO"
    $contenido += "================================"

    $networkPath = "HKCU:\Network"

    if (Test-Path $networkPath) {
        Get-ChildItem $networkPath | ForEach-Object {
            $drive = Split-Path $_.Name -Leaf
            $props = Get-ItemProperty $_.PsPath

            $contenido += "Unidad: $drive`:"
            $contenido += "Ruta: $($props.RemotePath)"
            $contenido += ""
        }
    }
    else {
        $contenido += "No se encontraron unidades en HKCU:\Network."
    }

    $contenido | Out-File $ruta -Encoding UTF8

    [System.Windows.Forms.MessageBox]::Show(
        "Backup guardado en:`n$ruta",
        "Pellati-Toolkit",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

function Mostrar-ConfiguracionIP {

    $formIP = New-Object System.Windows.Forms.Form
    $formIP.Text = "Configuración IP"
    $formIP.ClientSize = New-Object System.Drawing.Size(650,420)
    $formIP.StartPosition = "CenterScreen"

    $txtIP = New-Object System.Windows.Forms.TextBox
    $txtIP.Multiline = $true
    $txtIP.ReadOnly = $true
    $txtIP.ScrollBars = "Vertical"
    $txtIP.Font = New-Object System.Drawing.Font("Consolas",9)
    $txtIP.Size = New-Object System.Drawing.Size(600,280)
    $txtIP.Location = New-Object System.Drawing.Point(20,20)
    $formIP.Controls.Add($txtIP)

    function Obtener-ConfiguracionIP {
        Get-NetIPConfiguration |
            Where-Object { $_.IPv4Address -ne $null } |
            ForEach-Object {
@"
Adaptador: $($_.InterfaceAlias)
Descripción: $($_.InterfaceDescription)
IP: $($_.IPv4Address.IPAddress)
Máscara: $($_.IPv4Address.PrefixLength)
Puerta de enlace: $($_.IPv4DefaultGateway.NextHop)
DNS: $((Get-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4).ServerAddresses -join ", ")

"@
            } | Out-String
    }

    function Actualizar-ConfiguracionIP {
        try {
            $txtIP.Text = Obtener-ConfiguracionIP
        }
        catch {
            $txtIP.Text = "No se pudo obtener la configuración IP."
        }
    }

    function Exportar-ConfiguracionIP {

        $BackupPath = Obtener-CarpetaBackup

        $respuesta = [System.Windows.Forms.MessageBox]::Show(
            "Se exportará la configuración IP en la carpeta:`n$BackupPath`n`n¿Desea continuar?",
            "Exportar configuración IP",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) { return }

        $ruta = Join-Path $BackupPath "ConfiguracionIP.txt"
        Obtener-ConfiguracionIP | Out-File $ruta -Encoding UTF8

        [System.Windows.Forms.MessageBox]::Show(
            "Backup guardado en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }

    $btnActualizar = New-Object System.Windows.Forms.Button
    $btnActualizar.Text = "Actualizar"
    $btnActualizar.Size = New-Object System.Drawing.Size(120,35)
    $btnActualizar.Location = New-Object System.Drawing.Point(190,320)
    $btnActualizar.Add_Click({ Actualizar-ConfiguracionIP })
    $formIP.Controls.Add($btnActualizar)

    $btnExportar = New-Object System.Windows.Forms.Button
    $btnExportar.Text = "Exportar TXT"
    $btnExportar.Size = New-Object System.Drawing.Size(120,35)
    $btnExportar.Location = New-Object System.Drawing.Point(340,320)
    $btnExportar.Add_Click({ Exportar-ConfiguracionIP })
    $formIP.Controls.Add($btnExportar)

    Actualizar-ConfiguracionIP
    [void]$formIP.ShowDialog()
}

function Mostrar-RecursosCompartidos {

    $formShares = New-Object System.Windows.Forms.Form
    $formShares.Text = "Recursos compartidos"
    $formShares.ClientSize = New-Object System.Drawing.Size(650,400)
    $formShares.StartPosition = "CenterScreen"

    $txtShares = New-Object System.Windows.Forms.TextBox
    $txtShares.Multiline = $true
    $txtShares.ReadOnly = $true
    $txtShares.ScrollBars = "Vertical"
    $txtShares.Font = New-Object System.Drawing.Font("Consolas",9)
    $txtShares.Size = New-Object System.Drawing.Size(600,280)
    $txtShares.Location = New-Object System.Drawing.Point(20,20)
    $formShares.Controls.Add($txtShares)

    function Actualizar-RecursosCompartidos {
        try {
            $txtShares.Text = Get-SmbShare |
                Select-Object Name, Path, Description |
                Format-Table -AutoSize |
                Out-String
        }
        catch {
            $txtShares.Text = "No se pudieron obtener los recursos compartidos."
        }
    }

    $btnActualizar = New-Object System.Windows.Forms.Button
    $btnActualizar.Text = "Actualizar"
    $btnActualizar.Size = New-Object System.Drawing.Size(120,35)
    $btnActualizar.Location = New-Object System.Drawing.Point(190,320)
    $btnActualizar.Add_Click({ Actualizar-RecursosCompartidos })
    $formShares.Controls.Add($btnActualizar)

    $btnExportar = New-Object System.Windows.Forms.Button
    $btnExportar.Text = "Exportar TXT"
    $btnExportar.Size = New-Object System.Drawing.Size(120,35)
    $btnExportar.Location = New-Object System.Drawing.Point(340,320)
    $btnExportar.Add_Click({
        try {
            $BackupPath = Obtener-CarpetaBackup

            $respuesta = [System.Windows.Forms.MessageBox]::Show(
                "Se exportarán los recursos compartidos en la carpeta:`n$BackupPath`n`n¿Desea continuar?",
                "Exportar recursos compartidos",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) { return }

            $ruta = Join-Path $BackupPath "RecursosCompartidos.txt"

            Get-SmbShare |
                Select-Object Name, Path, Description |
                Format-Table -AutoSize |
                Out-File $ruta -Encoding UTF8

            [System.Windows.Forms.MessageBox]::Show(
                "Backup guardado en:`n$ruta",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "No se pudieron exportar los recursos compartidos.",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    })
    $formShares.Controls.Add($btnExportar)

    Actualizar-RecursosCompartidos
    [void]$formShares.ShowDialog()
}

function Mostrar-Sistema {

    $formSistema = New-Object System.Windows.Forms.Form
    $formSistema.Text = "Sistema"
    $formSistema.ClientSize = New-Object System.Drawing.Size(420,800)
    $formSistema.StartPosition = "CenterScreen"
    $formSistema.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    $panelSistema = New-Object System.Windows.Forms.Panel
    $panelSistema.Dock = "Fill"
    $panelSistema.AutoScroll = $true
    $panelSistema.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)
    $formSistema.Controls.Add($panelSistema)
function Alternar-AgrupacionBarraTareas {

    $rutaRegistro = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $nombreValor = "TaskbarGlomLevel"

    try {
        # Detectar sistema operativo
        $sistema = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $nombreWindows = $sistema.Caption
        $buildWindows = [int]$sistema.BuildNumber

        $esWindows10 = $nombreWindows -like "*Windows 10*"
        $esWindows11 = $nombreWindows -like "*Windows 11*"

        if (-not $esWindows10 -and -not $esWindows11) {
            [System.Windows.Forms.MessageBox]::Show(
                "Esta función está diseñada para Windows 10 y Windows 11.",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )

            return
        }

        # Crear la clave si no existe
        if (-not (Test-Path $rutaRegistro)) {
            New-Item `
                -Path $rutaRegistro `
                -Force `
                -ErrorAction Stop |
                Out-Null
        }

        # Obtener valor actual.
        # Si no existe, Windows usa el comportamiento predeterminado: agrupar.
        $propiedad = Get-ItemProperty `
            -Path $rutaRegistro `
            -Name $nombreValor `
            -ErrorAction SilentlyContinue

        if ($null -eq $propiedad) {
            $valorActual = 0
        }
        else {
            $valorActual = [int]$propiedad.$nombreValor
        }

        $estaDesagrupado = ($valorActual -eq 2)

        if ($estaDesagrupado) {

            $mensaje = @"
Sistema detectado:

$nombreWindows
Build: $buildWindows

Estado actual:

Los botones de la barra de tareas están DESAGRUPADOS.

¿Desea volver a agruparlos?
"@

            $titulo = "Agrupar botones de la barra de tareas"
            $nuevoValor = 0
            $mensajeFinal = "Los botones de la barra de tareas fueron agrupados correctamente."
        }
        else {

            $estadoActual = switch ($valorActual) {
                1 { "Se agrupan cuando la barra de tareas está llena." }
                default { "Se agrupan siempre." }
            }

            $mensaje = @"
Sistema detectado:

$nombreWindows
Build: $buildWindows

Estado actual:

$estadoActual

¿Desea desagrupar los botones de la barra de tareas y mostrar sus etiquetas?
"@

            $titulo = "Desagrupar botones de la barra de tareas"
            $nuevoValor = 2
            $mensajeFinal = "Los botones de la barra de tareas fueron desagrupados correctamente."
        }

        $respuesta = [System.Windows.Forms.MessageBox]::Show(
            $mensaje,
            $titulo,
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
            return
        }

        # Aplicar en la barra principal
        New-ItemProperty `
            -Path $rutaRegistro `
            -Name "TaskbarGlomLevel" `
            -PropertyType DWord `
            -Value $nuevoValor `
            -Force `
            -ErrorAction Stop |
            Out-Null

        # Aplicar también en barras de monitores secundarios
        New-ItemProperty `
            -Path $rutaRegistro `
            -Name "MMTaskbarGlomLevel" `
            -PropertyType DWord `
            -Value $nuevoValor `
            -Force `
            -ErrorAction SilentlyContinue |
            Out-Null

        # Reiniciar el Explorador para aplicar el cambio
        Get-Process explorer -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue

        Start-Sleep -Milliseconds 700
        Start-Process "explorer.exe"

        [System.Windows.Forms.MessageBox]::Show(
            $mensajeFinal,
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo modificar la agrupación de la barra de tareas.`n`nDetalle:`n$($_.Exception.Message)",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
function Abrir-AplicacionesPredeterminadas {

    try {
        Start-Process "ms-settings:defaultapps"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo abrir Aplicaciones predeterminadas.`n`n$($_.Exception.Message)",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
function Asociar-PdfYArchivosWeb {

    $extensiones = @(
        @{
            Extension   = ".pdf"
            Descripcion = "documentos PDF"
        },
        @{
            Extension   = ".html"
            Descripcion = "archivos HTML"
        },
        @{
            Extension   = ".htm"
            Descripcion = "archivos HTM"
        },
        @{
            Extension   = ".mhtml"
            Descripcion = "archivos MHTML"
        }
    )

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
Se crearán archivos ficticios temporales para configurar las siguientes asociaciones:

- PDF
- HTML
- HTM
- MHTML

Para cada archivo:

1. Se abrirán sus Propiedades.
2. En "Se abre con", presione "Cambiar".
3. Seleccione Acrobat Reader, Chrome u otro programa.
4. Presione Aplicar y Aceptar.
5. Vuelva a Pellati-Toolkit para continuar con la siguiente extensión.

¿Desea continuar?
"@,
        "Asociar PDF y archivos web",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    foreach ($item in $extensiones) {

        $extension = $item.Extension
        $descripcion = $item.Descripcion
        $archivoTemporal = $null

        try {
            $nombreTemporal = "Pellati_Asociacion_$([Guid]::NewGuid().ToString('N'))$extension"
            $archivoTemporal = Join-Path $env:TEMP $nombreTemporal

            New-Item `
                -Path $archivoTemporal `
                -ItemType File `
                -Force `
                -ErrorAction Stop |
                Out-Null

            $shell = New-Object -ComObject Shell.Application
            $carpeta = $shell.Namespace((Split-Path $archivoTemporal -Parent))
            $archivo = $carpeta.ParseName((Split-Path $archivoTemporal -Leaf))

            if (-not $archivo) {
                throw "No se pudo localizar el archivo temporal $extension."
            }

            $archivo.InvokeVerb("properties")

            [System.Windows.Forms.MessageBox]::Show(
@"
Se abrieron las propiedades para:

$extension - $descripcion

En "Se abre con":

1. Presione Cambiar.
2. Seleccione el programa deseado.
3. Presione Aplicar y Aceptar.

Cuando termine, presione Aceptar en este mensaje para continuar con la siguiente extensión.
"@,
                "Asociar $extension",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "No se pudo configurar $extension.`n`n$($_.Exception.Message)",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
        finally {
            if (
                $archivoTemporal -and
                (Test-Path -LiteralPath $archivoTemporal)
            ) {
                Remove-Item `
                    -LiteralPath $archivoTemporal `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
        }
    }

    [System.Windows.Forms.MessageBox]::Show(
        "El proceso de asociación de PDF y archivos web finalizó.",
        "Pellati-Toolkit",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}
    function Crear-BotonSistema {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($panelSistema.ClientSize.Width - $btn.Width) / 2)
        $btn.Location = New-Object System.Drawing.Point($x,$Y)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $panelSistema.Controls.Add($btn)
    }

    Crear-BotonSistema "Nombre del equipo" 40 {
    Abrir-NombreEquipo
}

Crear-BotonSistema "Acerca del equipo" 95 {
    Abrir-AcercaEquipo
}

Crear-BotonSistema "Programas al inicio" 150 {
    Abrir-AppsInicio
}

Crear-BotonSistema "Protección del sistema" 205 {
    Abrir-ProteccionSistema
}

Crear-BotonSistema "Administrador de tareas" 260 {
    Abrir-Taskmgr
}

Crear-BotonSistema "Servicios" 315 {
    Abrir-Servicios
}

Crear-BotonSistema "Administrador de dispositivos" 370 {
    Abrir-AdministradorDispositivos
}

Crear-BotonSistema "Iconos de escritorio" 425 {
    Abrir-IconosEscritorio
}

Crear-BotonSistema "Opciones de carpeta" 480 {
    Abrir-OpcionesCarpeta
}

Crear-BotonSistema "Carpetas de Windows" 535 {
    Mostrar-CarpetasWindows
}

Crear-BotonSistema "Agrupar / desagrupar barra de tareas" 590 {
    Alternar-AgrupacionBarraTareas
}

Crear-BotonSistema "Aplicaciones predeterminadas" 645 {
    Abrir-AplicacionesPredeterminadas
}

Crear-BotonSistema "Asociar PDF y archivos web" 700 {
    Asociar-PdfYArchivosWeb
}
    

$lblEspacio = New-Object System.Windows.Forms.Label
$lblEspacio.Location = New-Object System.Drawing.Point(0,780)
$lblEspacio.Size = New-Object System.Drawing.Size(1,50)
$panelSistema.Controls.Add($lblEspacio)
    [void]$formSistema.ShowDialog()
}