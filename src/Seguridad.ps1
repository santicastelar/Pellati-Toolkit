function Test-ToolkitAdministrador {
    try {
        $identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identidad)

        return $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    }
    catch {
        return $false
    }
}

function Test-DefenderDisponible {
    return [bool](Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)
}

function Abrir-SeguridadWindowsDefender {
    try {
        Start-Process "windowsdefender://threatsettings/"
    }
    catch {
        Start-Process "windowsdefender:"
    }
}

function Obtener-EstadoDefender {
    try {
        if (-not (Test-DefenderDisponible)) {
            throw "Microsoft Defender no está disponible o hay otro antivirus administrando la protección."
        }

        $estado = Get-MpComputerStatus -ErrorAction Stop
        $preferencias = Get-MpPreference -ErrorAction Stop

        $proteccionTexto = if ($estado.RealTimeProtectionEnabled) {
            "ACTIVADA"
        }
        else {
            "DESACTIVADA"
        }

        $tamperTexto = if ($estado.IsTamperProtected) {
            "ACTIVADA"
        }
        else {
            "DESACTIVADA"
        }

        $antivirusTexto = if ($estado.AntivirusEnabled) {
            "ACTIVADO"
        }
        else {
            "DESACTIVADO"
        }

        $antispywareTexto = if ($estado.AntispywareEnabled) {
            "ACTIVADO"
        }
        else {
            "DESACTIVADO"
        }

        [void][System.Windows.Forms.MessageBox]::Show(
@"
Estado de Microsoft Defender

Protección en tiempo real: $proteccionTexto
Protección contra alteraciones: $tamperTexto
Antivirus: $antivirusTexto
Antispyware: $antispywareTexto

DisableRealtimeMonitoring:
$($preferencias.DisableRealtimeMonitoring)
"@,
            "Estado de Windows Defender",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [void][System.Windows.Forms.MessageBox]::Show(
            "No se pudo consultar el estado de Windows Defender.`n`n$($_.Exception.Message)",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Desactivar-DefenderTiempoReal {
    try {
        if (-not (Test-ToolkitAdministrador)) {
            [void][System.Windows.Forms.MessageBox]::Show(
                "Esta función requiere ejecutar Pellati-Toolkit como administrador.",
                "Permisos insuficientes",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

        if (-not (Test-DefenderDisponible)) {
            throw "Microsoft Defender no está disponible o hay otro antivirus administrando la protección."
        }

        $estado = Get-MpComputerStatus -ErrorAction Stop

        if (-not $estado.RealTimeProtectionEnabled) {
            [void][System.Windows.Forms.MessageBox]::Show(
                "La protección en tiempo real ya se encuentra desactivada.",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            return
        }

        if ($estado.IsTamperProtected) {
            $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
La Protección contra alteraciones está activada.

Windows no permite desactivar la protección en tiempo real mediante PowerShell mientras esta opción esté habilitada, incluso ejecutando como administrador.

Se abrirá Seguridad de Windows para que pueda desactivar manualmente la opción:

Protección contra alteraciones

Luego vuelva a intentarlo desde Pellati-Toolkit.

¿Desea abrir Seguridad de Windows?
"@,
                "Protección contra alteraciones",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )

            if ($respuesta -eq [System.Windows.Forms.DialogResult]::Yes) {
                Abrir-SeguridadWindowsDefender
            }

            return
        }

        $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
Se desactivará temporalmente la protección en tiempo real de Microsoft Defender.

El equipo quedará con menor protección mientras esta opción permanezca desactivada.

¿Desea continuar?
"@,
            "Desactivar Windows Defender",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
            return
        }

        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
        Start-Sleep -Seconds 1

        $estadoActualizado = Get-MpComputerStatus -ErrorAction Stop

        if ($estadoActualizado.RealTimeProtectionEnabled) {
            throw "La protección en tiempo real continúa activada. Revise la Protección contra alteraciones o las políticas del equipo."
        }

        [void][System.Windows.Forms.MessageBox]::Show(
            "La protección en tiempo real fue desactivada correctamente.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [void][System.Windows.Forms.MessageBox]::Show(
            "No se pudo desactivar la protección en tiempo real.`n`n$($_.Exception.Message)",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Activar-DefenderTiempoReal {
    try {
        if (-not (Test-ToolkitAdministrador)) {
            [void][System.Windows.Forms.MessageBox]::Show(
                "Esta función requiere ejecutar Pellati-Toolkit como administrador.",
                "Permisos insuficientes",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

        if (-not (Test-DefenderDisponible)) {
            throw "Microsoft Defender no está disponible o hay otro antivirus administrando la protección."
        }

        $estadoInicial = Get-MpComputerStatus -ErrorAction Stop

        if ($estadoInicial.RealTimeProtectionEnabled) {
            [void][System.Windows.Forms.MessageBox]::Show(
                "La protección en tiempo real ya se encuentra activada.",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            return
        }

        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
        Start-Sleep -Seconds 1

        $estado = Get-MpComputerStatus -ErrorAction Stop

        if (-not $estado.RealTimeProtectionEnabled) {
            throw "Windows Defender continúa desactivado. Revise las políticas de seguridad del equipo."
        }

        [void][System.Windows.Forms.MessageBox]::Show(
            "La protección en tiempo real fue activada correctamente.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [void][System.Windows.Forms.MessageBox]::Show(
            "No se pudo activar la protección en tiempo real.`n`n$($_.Exception.Message)",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Mostrar-ExclusionesDefender {
    try {
        if (-not (Test-DefenderDisponible)) {
            throw "Microsoft Defender no está disponible o hay otro antivirus administrando la protección."
        }

        $exclusiones = @(
            (Get-MpPreference -ErrorAction Stop).ExclusionPath
        ) | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        } | Sort-Object -Unique

        $formExclusiones = New-Object System.Windows.Forms.Form
        $formExclusiones.Text = "Exclusiones de Windows Defender"
        $formExclusiones.ClientSize = New-Object System.Drawing.Size(650,420)
        $formExclusiones.StartPosition = "CenterScreen"
        $formExclusiones.FormBorderStyle = "FixedDialog"
        $formExclusiones.MaximizeBox = $false
        $formExclusiones.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

        $txtExclusiones = New-Object System.Windows.Forms.TextBox
        $txtExclusiones.Multiline = $true
        $txtExclusiones.ReadOnly = $true
        $txtExclusiones.ScrollBars = "Vertical"
        $txtExclusiones.Font = New-Object System.Drawing.Font("Consolas",9)
        $txtExclusiones.Location = New-Object System.Drawing.Point(20,20)
        $txtExclusiones.Size = New-Object System.Drawing.Size(600,330)

        if ($exclusiones.Count -eq 0) {
            $txtExclusiones.Text = "No se encontraron exclusiones de ruta."
        }
        else {
            $txtExclusiones.Text = $exclusiones -join [Environment]::NewLine
        }

        $btnCerrar = New-Object System.Windows.Forms.Button
        $btnCerrar.Text = "Cerrar"
        $btnCerrar.Size = New-Object System.Drawing.Size(100,35)
        $btnCerrar.Location = New-Object System.Drawing.Point(520,365)
        $btnCerrar.DialogResult = [System.Windows.Forms.DialogResult]::OK

        $formExclusiones.AcceptButton = $btnCerrar
        $formExclusiones.CancelButton = $btnCerrar
        $formExclusiones.Controls.Add($txtExclusiones)
        $formExclusiones.Controls.Add($btnCerrar)

        [void]$formExclusiones.ShowDialog()
    }
    catch {
        [void][System.Windows.Forms.MessageBox]::Show(
            "No se pudieron consultar las exclusiones.`n`n$($_.Exception.Message)",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Agregar-ExclusionDefender {
    if (-not (Test-ToolkitAdministrador)) {
        [void][System.Windows.Forms.MessageBox]::Show(
            "Esta función requiere ejecutar Pellati-Toolkit como administrador.",
            "Permisos insuficientes",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }

    if (-not (Test-DefenderDisponible)) {
        [void][System.Windows.Forms.MessageBox]::Show(
            "Microsoft Defender no está disponible o hay otro antivirus administrando la protección.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }

    $formRuta = New-Object System.Windows.Forms.Form
    $formRuta.Text = "Agregar exclusión"
    $formRuta.ClientSize = New-Object System.Drawing.Size(580,210)
    $formRuta.StartPosition = "CenterScreen"
    $formRuta.FormBorderStyle = "FixedDialog"
    $formRuta.MaximizeBox = $false
    $formRuta.MinimizeBox = $false
    $formRuta.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    $lblRuta = New-Object System.Windows.Forms.Label
    $lblRuta.Text = "Pegue, escriba o seleccione la ruta que desea excluir:"
    $lblRuta.AutoSize = $true
    $lblRuta.Location = New-Object System.Drawing.Point(20,20)

    $txtRuta = New-Object System.Windows.Forms.TextBox
    $txtRuta.Location = New-Object System.Drawing.Point(20,55)
    $txtRuta.Size = New-Object System.Drawing.Size(530,25)

    $btnExaminar = New-Object System.Windows.Forms.Button
    $btnExaminar.Text = "Examinar carpeta"
    $btnExaminar.Size = New-Object System.Drawing.Size(130,35)
    $btnExaminar.Location = New-Object System.Drawing.Point(20,100)

    $btnAgregar = New-Object System.Windows.Forms.Button
    $btnAgregar.Text = "Agregar"
    $btnAgregar.Size = New-Object System.Drawing.Size(100,35)
    $btnAgregar.Location = New-Object System.Drawing.Point(340,100)

    $btnCancelar = New-Object System.Windows.Forms.Button
    $btnCancelar.Text = "Cancelar"
    $btnCancelar.Size = New-Object System.Drawing.Size(100,35)
    $btnCancelar.Location = New-Object System.Drawing.Point(450,100)
    $btnCancelar.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $btnExaminar.Add_Click({
        $selector = New-Object System.Windows.Forms.FolderBrowserDialog
        $selector.Description = "Seleccione la carpeta que desea excluir"
        $selector.ShowNewFolderButton = $true

        if ($selector.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtRuta.Text = $selector.SelectedPath
        }
    })

    $btnAgregar.Add_Click({
        $ruta = $txtRuta.Text.Trim().Trim('"')

        if ([string]::IsNullOrWhiteSpace($ruta)) {
            [void][System.Windows.Forms.MessageBox]::Show(
                "Debe ingresar una ruta.",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

        if (-not (Test-Path -LiteralPath $ruta)) {
            [void][System.Windows.Forms.MessageBox]::Show(
                "La ruta ingresada no existe:`n$ruta",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

        try {
            $rutaNormalizada = (Resolve-Path -LiteralPath $ruta -ErrorAction Stop).Path
        }
        catch {
            $rutaNormalizada = $ruta
        }

        $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
Se agregará la siguiente ruta como exclusión de Microsoft Defender:

$rutaNormalizada

Los archivos ubicados allí no serán analizados normalmente por Defender.

¿Desea continuar?
"@,
            "Agregar exclusión",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
            return
        }

        try {
            $existentes = @(
                (Get-MpPreference -ErrorAction Stop).ExclusionPath
            ) | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            }

            if ($existentes -contains $rutaNormalizada) {
                [void][System.Windows.Forms.MessageBox]::Show(
                    "La ruta ya se encuentra agregada como exclusión.",
                    "Pellati-Toolkit",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
                return
            }

            Add-MpPreference -ExclusionPath $rutaNormalizada -ErrorAction Stop

            [void][System.Windows.Forms.MessageBox]::Show(
                "La exclusión fue agregada correctamente.`n`n$rutaNormalizada",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )

            $formRuta.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $formRuta.Close()
        }
        catch {
            [void][System.Windows.Forms.MessageBox]::Show(
                "No se pudo agregar la exclusión.`n`n$($_.Exception.Message)",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    })

    $formRuta.AcceptButton = $btnAgregar
    $formRuta.CancelButton = $btnCancelar
    $formRuta.Controls.Add($lblRuta)
    $formRuta.Controls.Add($txtRuta)
    $formRuta.Controls.Add($btnExaminar)
    $formRuta.Controls.Add($btnAgregar)
    $formRuta.Controls.Add($btnCancelar)

    [void]$formRuta.ShowDialog()
}

function Mostrar-Seguridad {
    $formSeguridad = New-Object System.Windows.Forms.Form
    $formSeguridad.Text = "Seguridad"
    $formSeguridad.ClientSize = New-Object System.Drawing.Size(420,390)
    $formSeguridad.StartPosition = "CenterScreen"
    $formSeguridad.FormBorderStyle = "FixedDialog"
    $formSeguridad.MaximizeBox = $false
    $formSeguridad.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonSeguridad {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($formSeguridad.ClientSize.Width - $btn.Width) / 2)
        $btn.Location = New-Object System.Drawing.Point($x,$Y)
        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $formSeguridad.Controls.Add($btn)
    }

    Crear-BotonSeguridad "Estado de Windows Defender" 40 {
        Obtener-EstadoDefender
    }

    Crear-BotonSeguridad "Desactivar protección en tiempo real" 95 {
        Desactivar-DefenderTiempoReal
    }

    Crear-BotonSeguridad "Activar protección en tiempo real" 150 {
        Activar-DefenderTiempoReal
    }

    Crear-BotonSeguridad "Ver exclusiones" 205 {
        Mostrar-ExclusionesDefender
    }

    Crear-BotonSeguridad "Agregar exclusión" 260 {
        Agregar-ExclusionDefender
    }

    Crear-BotonSeguridad "Abrir Seguridad de Windows" 315 {
        Abrir-SeguridadWindowsDefender
    }

    [void]$formSeguridad.ShowDialog()
}