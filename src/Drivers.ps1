function Mostrar-Drivers {

    $formDrivers = New-Object System.Windows.Forms.Form
    $formDrivers.Text = "Drivers"
    $formDrivers.ClientSize = New-Object System.Drawing.Size(420,300)
    $formDrivers.StartPosition = "CenterScreen"
    $formDrivers.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonDrivers {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($formDrivers.ClientSize.Width - $btn.Width)/2)
        $btn.Location = New-Object System.Drawing.Point($x,$Y)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $formDrivers.Controls.Add($btn)
    }

    Crear-BotonDrivers "Rapr (Driver Store Explorer)" 40 {
        Abrir-Rapr
    }
function Abrir-Rapr {

    $ruta = Join-Path $ToolsPath "Rapr\Rapr.exe"

    if (Test-Path $ruta) {
        Start-Process $ruta -Verb RunAs
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró Rapr.exe.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
    [void]$formDrivers.ShowDialog()
}