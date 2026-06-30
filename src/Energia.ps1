function Mostrar-Energia {

    $formEnergia = New-Object System.Windows.Forms.Form
    $formEnergia.Text = "Energía"
    $formEnergia.ClientSize = New-Object System.Drawing.Size(420,180)
    $formEnergia.StartPosition = "CenterScreen"
    $formEnergia.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonEnergia {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($formEnergia.ClientSize.Width - $btn.Width) / 2)
        $btn.Location = New-Object System.Drawing.Point($x,$Y)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $formEnergia.Controls.Add($btn)
    }

    Crear-BotonEnergia "Editar plan de energía" 40 {
        Abrir-EditarPlanEnergia
    }

    Crear-BotonEnergia "Configurar energía técnica" 95 {

        $mensaje = @"
Se aplicará la siguiente configuración:

1. El equipo nunca se suspenderá.
2. La pantalla nunca se apagará.
3. Los discos nunca se apagarán.
4. Se deshabilitará la hibernación.
5. Se detectará automáticamente si es notebook o PC de escritorio.

¿Desea continuar?
"@

        $respuesta = [System.Windows.Forms.MessageBox]::Show(
            $mensaje,
            "Configuración de energía",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($respuesta -eq [System.Windows.Forms.DialogResult]::Yes) {

            Configurar-Energia

            [System.Windows.Forms.MessageBox]::Show(
                "La configuración fue aplicada correctamente.",
                "Pellati-Toolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }

    [void]$formEnergia.ShowDialog()
}