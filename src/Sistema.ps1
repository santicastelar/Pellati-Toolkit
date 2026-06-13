function Abrir-NombreEquipo {
    Start-Process "sysdm.cpl"
}
function Abrir-AcercaEquipo {
    Start-Process "control.exe" -ArgumentList "system"
}
function Abrir-SeguridadWindows {
    Start-Process "windowsdefender://threat/"
}
function Abrir-IconosEscritorio {
    Start-Process "rundll32.exe" -ArgumentList "shell32.dll,Control_RunDLL desk.cpl,,0"
}
function Abrir-Taskmgr {
    taskmgr.exe 
}
function Abrir-OpcionesCarpeta {
    Start-Process "control.exe" -ArgumentList "folders"
}
function Abrir-ProteccionSistema {
    Start-Process "SystemPropertiesProtection.exe"
}
function Abrir-ProgramasInstalados {
    Start-Process "appwiz.cpl"
}

function Abrir-AppsInicio {
    Start-Process "ms-settings:startupapps"
}
function Abrir-AdministradorDispositivos {
    Start-Process "devmgmt.msc"
}

function Abrir-AdministracionDiscos {
    Start-Process "diskmgmt.msc"
}

function Abrir-Servicios {
    Start-Process "services.msc"
}
function Mostrar-Sistema {

    $formSistema = New-Object System.Windows.Forms.Form
    $formSistema.Text = "Sistema"
    $formSistema.ClientSize = New-Object System.Drawing.Size(420,900)
    $formSistema.StartPosition = "CenterScreen"
    $formSistema.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonSistema {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($formSistema.ClientSize.Width - $btn.Width) / 2)
        $btn.Location = New-Object System.Drawing.Point($x,$Y)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $formSistema.Controls.Add($btn)
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

            $shares = Get-SmbShare |
                Select-Object Name, Path, Description |
                Format-Table -AutoSize |
                Out-String

            $txtShares.Text = $shares

        }
        catch {

            $txtShares.Text = "No se pudieron obtener los recursos compartidos."
        }
    }

    $btnActualizar = New-Object System.Windows.Forms.Button
    $btnActualizar.Text = "Actualizar"
    $btnActualizar.Size = New-Object System.Drawing.Size(120,35)
    $btnActualizar.Location = New-Object System.Drawing.Point(250,320)

    $btnActualizar.Add_Click({
        Actualizar-RecursosCompartidos
    })

    $formShares.Controls.Add($btnActualizar)

    Actualizar-RecursosCompartidos

    [void]$formShares.ShowDialog()
}
Crear-BotonSistema "Acerca del equipo" 40 {
    Abrir-AcercaEquipo
}

Crear-BotonSistema "Nombre del equipo" 95 {
    Abrir-NombreEquipo
}

Crear-BotonSistema "Programas instalados" 150 {
    Abrir-ProgramasInstalados
}

Crear-BotonSistema "Programas al inicio" 205 {
    Abrir-AppsInicio
}

Crear-BotonSistema "Administrador de tareas" 260 {
    Abrir-Taskmgr
}

Crear-BotonSistema "Administrador de dispositivos" 315 {
    Abrir-AdministradorDispositivos
}

Crear-BotonSistema "Administracion de discos" 370 {
    Abrir-AdministracionDiscos
}

Crear-BotonSistema "Servicios" 425 {
    Abrir-Servicios
}

Crear-BotonSistema "Iconos de escritorio" 480 {
    Abrir-IconosEscritorio
}

Crear-BotonSistema "Opciones de carpeta" 535 {
    Abrir-OpcionesCarpeta
}

Crear-BotonSistema "Seguridad de Windows" 590 {
    Abrir-SeguridadWindows
}

Crear-BotonSistema "Proteccion del sistema" 645 {
    Abrir-ProteccionSistema
}

Crear-BotonSistema "BitLocker C:" 700 {
    Mostrar-BitLocker
}
Crear-BotonSistema "Recursos compartidos" 755 {
    Mostrar-RecursosCompartidos
}
Crear-BotonSistema "Configurar energia tecnica" 810 {

$mensaje = @"
Se aplicara la siguiente configuracion:

1. El equipo nunca se suspendera.
2. La pantalla se apagara despues de 1 hora.
3. Se detecta automaticamente si es notebook o PC de escritorio.

Desea continuar?
"@

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
        $mensaje,
        "Configuracion de energia",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -eq [System.Windows.Forms.DialogResult]::Yes) {
        Configurar-Energia

        [System.Windows.Forms.MessageBox]::Show(
            "La configuracion fue aplicada correctamente.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
}



    [void]$formSistema.ShowDialog()
}
function Mostrar-BitLocker {

    $formBitLocker = New-Object System.Windows.Forms.Form
    $formBitLocker.Text = "BitLocker C:"
    $formBitLocker.ClientSize = New-Object System.Drawing.Size(430,260)
    $formBitLocker.StartPosition = "CenterScreen"

    $txtEstado = New-Object System.Windows.Forms.TextBox
    $txtEstado.Multiline = $true
    $txtEstado.ReadOnly = $true
    $txtEstado.ScrollBars = "Vertical"
    $txtEstado.Size = New-Object System.Drawing.Size(360,120)
    $txtEstado.Location = New-Object System.Drawing.Point(35,25)
    $formBitLocker.Controls.Add($txtEstado)

    function Actualizar-EstadoBitLocker {
        try {
            $vol = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop

            $txtEstado.Text = @"
Unidad: $($vol.MountPoint)
Estado: $($vol.VolumeStatus)
Proteccion: $($vol.ProtectionStatus)
Porcentaje cifrado: $($vol.EncryptionPercentage)%
Metodo: $($vol.EncryptionMethod)
"@
        }
        catch {
            $txtEstado.Text = "No se pudo obtener el estado de BitLocker."
        }
    }

    $btnActualizar = New-Object System.Windows.Forms.Button
    $btnActualizar.Text = "Actualizar estado"
    $btnActualizar.Size = New-Object System.Drawing.Size(160,35)
    $btnActualizar.Location = New-Object System.Drawing.Point(35,165)
    $btnActualizar.Add_Click({
        Actualizar-EstadoBitLocker
    })
    $formBitLocker.Controls.Add($btnActualizar)

    $btnDesactivar = New-Object System.Windows.Forms.Button
    $btnDesactivar.Text = "Desactivar BitLocker"
    $btnDesactivar.Size = New-Object System.Drawing.Size(170,35)
    $btnDesactivar.Location = New-Object System.Drawing.Point(225,165)
    $btnDesactivar.Add_Click({

        try {
            $vol = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop

            if ($vol.ProtectionStatus -eq "Off" -and $vol.VolumeStatus -eq "FullyDecrypted") {
                [System.Windows.Forms.MessageBox]::Show(
                    "BitLocker ya esta desactivado en la unidad C:.",
                    "BitLocker",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )

                Actualizar-EstadoBitLocker
                return
            }

            $respuesta = [System.Windows.Forms.MessageBox]::Show(
                "Se desactivara BitLocker en la unidad C: y comenzara el descifrado. Desea continuar?",
                "Confirmar BitLocker",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )

            if ($respuesta -eq [System.Windows.Forms.DialogResult]::Yes) {
                Disable-BitLocker -MountPoint "C:" -ErrorAction Stop
                Actualizar-EstadoBitLocker

                [System.Windows.Forms.MessageBox]::Show(
                    "Se inicio la desactivacion de BitLocker. Use Actualizar estado para ver el progreso.",
                    "BitLocker",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "No se pudo consultar o modificar BitLocker en la unidad C:.",
                "Error BitLocker",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    })
    $formBitLocker.Controls.Add($btnDesactivar)

    Actualizar-EstadoBitLocker

    [void]$formBitLocker.ShowDialog()
}