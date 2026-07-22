function Abrir-Telemetria {

    $ruta = Join-Path $ToolsPath "WPD\WPD.exe"

    if (Test-Path $ruta) {
        Start-Process $ruta
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró WPD.exe en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Abrir-ActivacionWindows {

    [System.Windows.Forms.MessageBox]::Show(
@"
Se abrirá la configuración oficial de activación de Windows.

Desde allí podrá consultar el estado de activación
o ingresar una clave de producto válida.
"@,
        "Activación de Windows",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )

    Start-Process "ms-settings:activation"
}

function Optimizar-Servicios {

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
Se realizarán las siguientes acciones:

- Detener y deshabilitar SysMain.
- Detener y deshabilitar BITS.

Advertencia:

Deshabilitar BITS puede afectar Windows Update,
Microsoft Store y otras descargas del sistema.

¿Desea continuar?
"@,
        "Optimizar servicios",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    # Comprobar permisos de administrador
    $identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identidad)

    $esAdministrador = $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if (-not $esAdministrador) {

        [System.Windows.Forms.MessageBox]::Show(
            "Esta función requiere ejecutar Pellati-Toolkit como administrador.",
            "Permisos insuficientes",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        return
    }

    try {

        $servicios = @(
            "SysMain",
            "BITS"
        )

        $errores = @()

        foreach ($servicio in $servicios) {

            $servicioActual = Get-Service `
                -Name $servicio `
                -ErrorAction SilentlyContinue

            if (-not $servicioActual) {
                $errores += "No se encontró el servicio $servicio."
                continue
            }

            # Detener el servicio si está ejecutándose
            if ($servicioActual.Status -ne "Stopped") {

                & sc.exe stop $servicio | Out-Null

                Start-Sleep -Milliseconds 800
            }

            # Configurar inicio como deshabilitado
            & sc.exe config $servicio start= disabled | Out-Null

            if ($LASTEXITCODE -ne 0) {
                $errores += "No se pudo deshabilitar el servicio $servicio."
            }
        }

        if ($errores.Count -gt 0) {
            throw ($errores -join "`n")
        }

        [System.Windows.Forms.MessageBox]::Show(
@"
Los servicios fueron configurados correctamente.

SysMain: Deshabilitado
BITS: Deshabilitado
"@,
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {

        [System.Windows.Forms.MessageBox]::Show(
            "No fue posible modificar los servicios.`n`n$($_.Exception.Message)",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Mostrar-Herramientas {

    $formHerramientas = New-Object System.Windows.Forms.Form
    $formHerramientas.Text = "Herramientas"
    $formHerramientas.ClientSize = New-Object System.Drawing.Size(420,250)
    $formHerramientas.StartPosition = "CenterScreen"
    $formHerramientas.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonHerramientas {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($formHerramientas.ClientSize.Width - $btn.Width) / 2)
        $btn.Location = New-Object System.Drawing.Point($x,$Y)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $formHerramientas.Controls.Add($btn)
    }

    Crear-BotonHerramientas "Activación de Windows" 40 {
        Abrir-ActivacionWindows
    }

    Crear-BotonHerramientas "Telemetría" 95 {
        Abrir-Telemetria
    }

    Crear-BotonHerramientas "Optimizar servicios" 150 {
        Optimizar-Servicios
    }

    [void]$formHerramientas.ShowDialog()
}