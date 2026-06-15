function Abrir-Lightshot {

    $ruta = Join-Path $PSScriptRoot "..\tools\LightshotPortable\LightshotPortable.exe"

    if (Test-Path $ruta) {
        Start-Process $ruta
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontro Lightshot en:`n$ruta",
            "Pellati-Toolkit"
        )
    }
}

function Mostrar-Programas {

    $formProgramas = New-Object System.Windows.Forms.Form
    $formProgramas.Text = "Programas"
    $formProgramas.ClientSize = New-Object System.Drawing.Size(420,300)
    $formProgramas.StartPosition = "CenterScreen"
    $formProgramas.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonProgramas {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($formProgramas.ClientSize.Width - $btn.Width) / 2)
        $btn.Location = New-Object System.Drawing.Point($x,$Y)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $formProgramas.Controls.Add($btn)
    }

    Crear-BotonProgramas "Lightshot Portable" 40 {
        Abrir-Lightshot
    }

    [void]$formProgramas.ShowDialog()
}