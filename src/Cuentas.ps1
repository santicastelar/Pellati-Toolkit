function Configurar-InicioSesionAutomatico {

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
Se habilitará la opción de inicio de sesión automático.

Luego se abrirá NETPLWIZ.

Pasos:

1. Destildar:
   "Los usuarios deben escribir su nombre y contraseña..."

2. Presionar Aplicar.

3. Escribir la contraseña del usuario.

¿Desea continuar?
"@,
        "Inicio de sesión automático",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device" `
    /v DevicePasswordLessBuildVersion `
    /t REG_DWORD `
    /d 0 `
    /f | Out-Null

Start-Sleep -Milliseconds 500

Start-Process netplwiz
}
function Aplicar-ConfiguracionCuentas {

    $usuarioActual = $env:USERNAME

    $mensaje = @"
Se aplicará la siguiente configuración:

1. El umbral de bloqueo de cuentas quedará en 0.
2. La cuenta no se bloqueará por intentos fallidos.
3. La contraseña del usuario local actual no vencerá.
4. Se actualizarán las directivas del equipo.

Usuario detectado:

$usuarioActual

Esta configuración reduce la protección frente a intentos repetidos de contraseña.

¿Desea continuar?
"@

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
        $mensaje,
        "Configuración de cuentas",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    try {
        $usuario = Get-LocalUser -Name $usuarioActual -ErrorAction Stop

        # Evitar que la cuenta se bloquee por intentos fallidos
        & net.exe accounts /lockoutthreshold:0 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "No se pudo modificar el umbral de bloqueo."
        }

        # Evitar que la contraseña del usuario local venza
        Set-LocalUser `
            -Name $usuario.Name `
            -PasswordNeverExpires $true `
            -ErrorAction Stop

        # Actualizar directivas
        & gpupdate.exe /target:computer /force | Out-Null

        [System.Windows.Forms.MessageBox]::Show(
@"
La configuración fue aplicada correctamente.

Usuario: $($usuario.Name)
Bloqueo por intentos fallidos: Desactivado
Contraseña: No vence
"@,
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo aplicar la configuración de cuentas.`n`nDetalle:`n$($_.Exception.Message)",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Ver-EstadoCuentas {

    try {
        $usuarioActual = $env:USERNAME
        $usuario = Get-LocalUser -Name $usuarioActual -ErrorAction Stop
        $netAccounts = & net.exe accounts | Out-String

        $formEstado = New-Object System.Windows.Forms.Form
        $formEstado.Text = "Estado de cuentas"
        $formEstado.ClientSize = New-Object System.Drawing.Size(650,430)
        $formEstado.StartPosition = "CenterScreen"

        $txtEstado = New-Object System.Windows.Forms.TextBox
        $txtEstado.Multiline = $true
        $txtEstado.ReadOnly = $true
        $txtEstado.ScrollBars = "Vertical"
        $txtEstado.Font = New-Object System.Drawing.Font("Consolas",9)
        $txtEstado.Size = New-Object System.Drawing.Size(600,360)
        $txtEstado.Location = New-Object System.Drawing.Point(20,20)

        $txtEstado.Text = @"
USUARIO LOCAL ACTUAL
====================

Nombre: $($usuario.Name)
Habilitado: $($usuario.Enabled)
La contraseña vence: $($usuario.PasswordExpires)
Último cambio de contraseña: $($usuario.PasswordLastSet)

POLÍTICA DE CUENTAS
===================

$netAccounts
"@

        $formEstado.Controls.Add($txtEstado)

        [void]$formEstado.ShowDialog()
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo consultar la configuración de cuentas.`n`n$($_.Exception.Message)",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Mostrar-Cuentas {

    $formCuentas = New-Object System.Windows.Forms.Form
    $formCuentas.Text = "Cuentas"
    $formCuentas.ClientSize = New-Object System.Drawing.Size(420,210)
    $formCuentas.StartPosition = "CenterScreen"
    $formCuentas.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonCuentas {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($formCuentas.ClientSize.Width - $btn.Width) / 2)
        $btn.Location = New-Object System.Drawing.Point($x,$Y)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $formCuentas.Controls.Add($btn)
    }

    Crear-BotonCuentas "Configurar cuenta técnica" 40 {
        Aplicar-ConfiguracionCuentas
    }

    Crear-BotonCuentas "Ver estado de cuentas" 95 {
        Ver-EstadoCuentas
    }

    Crear-BotonCuentas "Inicio de sesión automático" 150 {
    Configurar-InicioSesionAutomatico
}

    [void]$formCuentas.ShowDialog()
}