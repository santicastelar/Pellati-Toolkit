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

function Ejecutar-EnBackground {
    param([scriptblock]$ScriptBlock)
    
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    $ps.AddScript($ScriptBlock) | Out-Null
    $ps.BeginInvoke() | Out-Null
}

# Luego el botón queda así:
Crear-BotonHerramientas "Activar Windows / Office" 40 {
    $formHerramientas.Enabled = $false
    
    Ejecutar-EnBackground {
        try {
            irm https://get.activated.win | iex
            
            [System.Windows.Forms.MessageBox]::Show("Activación completada.", "Éxito", "OK", "Information")
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Error", "OK", "Error")
        }
    }
    
    $formHerramientas.Enabled = $true
}

    [void]$formHerramientas.ShowDialog()
}