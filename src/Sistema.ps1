function Abrir-NombreEquipo { Start-Process "sysdm.cpl" }
function Abrir-AcercaEquipo { Start-Process "control.exe" -ArgumentList "system" }
function Abrir-SeguridadWindows { Start-Process "windowsdefender://threat/" }
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
    $ruta = "$env:USERPROFILE\Desktop\Backup_Usuario.txt"

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
            "Pellati-Toolkit"
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

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
En el escritorio se creará un archivo llamado "NombreEquipo.txt".

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

    $ruta = "$env:USERPROFILE\Desktop\NombreEquipo.txt"

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

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
        "Se exportarán las unidades de red mapeadas a un archivo TXT en el Escritorio.`n`n¿Desea continuar?",
        "Exportar unidades de red",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $ruta = "$env:USERPROFILE\Desktop\UnidadesMapeadas.txt"
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
        $respuesta = [System.Windows.Forms.MessageBox]::Show(
            "Se exportará la configuración IP en un archivo TXT en el escritorio. ¿Desea continuar?",
            "Exportar configuración IP",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) { return }

        $ruta = "$env:USERPROFILE\Desktop\ConfiguracionIP.txt"
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
            $ruta = "$env:USERPROFILE\Desktop\RecursosCompartidos.txt"

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
    $formSistema.ClientSize = New-Object System.Drawing.Size(420,750)
    $formSistema.StartPosition = "CenterScreen"
    $formSistema.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    $panelSistema = New-Object System.Windows.Forms.Panel
    $panelSistema.Dock = "Fill"
    $panelSistema.AutoScroll = $true
    $panelSistema.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)
    $formSistema.Controls.Add($panelSistema)

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

Crear-BotonSistema "Protección del sistema" 95 {
    Abrir-ProteccionSistema
}

Crear-BotonSistema "Acerca del equipo" 150 {
    Abrir-AcercaEquipo
}

Crear-BotonSistema "Iconos de escritorio" 205 {
    Abrir-IconosEscritorio
}

Crear-BotonSistema "Seguridad de Windows" 260 {
    Abrir-SeguridadWindows
}

Crear-BotonSistema "Programas al inicio" 315 {
    Abrir-AppsInicio
}

Crear-BotonSistema "Administrador de dispositivos" 370 {
    Abrir-AdministradorDispositivos
}

Crear-BotonSistema "Administrador de tareas" 425 {
    Abrir-Taskmgr
}

Crear-BotonSistema "Servicios" 480 {
    Abrir-Servicios
}

Crear-BotonSistema "Opciones de carpeta" 535 {
    Abrir-OpcionesCarpeta
}

    $lblEspacio = New-Object System.Windows.Forms.Label
    $lblEspacio.Location = New-Object System.Drawing.Point(0,1120)
    $lblEspacio.Size = New-Object System.Drawing.Size(1,1)
    $panelSistema.Controls.Add($lblEspacio)

    [void]$formSistema.ShowDialog()
}