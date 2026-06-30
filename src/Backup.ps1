function Mostrar-Backup {

    $formBackup = New-Object System.Windows.Forms.Form
    $formBackup.Text = "Backup"
    $formBackup.ClientSize = New-Object System.Drawing.Size(420,630)
    $formBackup.StartPosition = "CenterScreen"
    $formBackup.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonBackup {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($formBackup.ClientSize.Width - $btn.Width) / 2)
        $btn.Location = New-Object System.Drawing.Point($x,$Y)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $formBackup.Controls.Add($btn)
    }

Crear-BotonBackup "Backup nombre del equipo" 40 {
    Exportar-NombreEquipo
}

Crear-BotonBackup "Backup Usuario y Contraseña" 95 {
    Exportar-UsuarioActual
}

Crear-BotonBackup "Backup configuración IP" 150 {
    Mostrar-ConfiguracionIP
}

Crear-BotonBackup "Backup unidades de red" 205 {
    Exportar-UnidadesMapeadas
}

Crear-BotonBackup "Backup recursos compartidos" 260 {
    Mostrar-RecursosCompartidos
}

Crear-BotonBackup "Backup Credenciales de Windows" 315 {
    Abrir-CredencialesWindows
}

    [void]$formBackup.ShowDialog()
}