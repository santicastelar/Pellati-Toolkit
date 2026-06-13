function Abrir-SeguridadWindows {
    Start-Process "windowsdefender://threat/"
}
function Abrir-IconosEscritorio {
    Start-Process "rundll32.exe" -ArgumentList "shell32.dll,Control_RunDLL desk.cpl,,0"
}
function Abrir-AppsInicio {
    taskmgr.exe /3
}

function Mostrar-Sistema {

    $formSistema = New-Object System.Windows.Forms.Form
    $formSistema.Text = "Sistema"
    $formSistema.ClientSize = New-Object System.Drawing.Size(420,500)
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


    Crear-BotonSistema "Mostrar extensiones" 85 {
        Mostrar-Extensiones
    }

    Crear-BotonSistema "Mostrar ocultos" 130 {
        Mostrar-Ocultos
    }

    Crear-BotonSistema "Desactivar inicio rapido" 175 {
        Desactivar-InicioRapido
    }

    Crear-BotonSistema "Limpiar temporales" 220 {
        Limpiar-Temporales
    }

    Crear-BotonSistema "Activar Restaurar Sistema" 265 {
        Activar-RestaurarSistema
    }

Crear-BotonSistema "Configurar energia tecnica" 310 {

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

    Crear-BotonSistema "Aplicaciones de inicio" 355 {
        Abrir-AppsInicio
    }

    Crear-BotonSistema "Seguridad de Windows" 400 {
        Abrir-SeguridadWindows
    }

    Crear-BotonSistema "Iconos de escritorio" 445 {
        Abrir-IconosEscritorio
    }

    [void]$formSistema.ShowDialog()
}