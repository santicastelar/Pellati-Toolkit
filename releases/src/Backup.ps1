function Obtener-CarpetaBackup {

    $nombrePC = $env:COMPUTERNAME

    $carpeta = Join-Path `
        ([Environment]::GetFolderPath("Desktop")) `
        "Pellati-Backup-$nombrePC"

    if (!(Test-Path $carpeta)) {
        New-Item -ItemType Directory -Path $carpeta | Out-Null
    }

    return $carpeta
}

function Exportar-ProgramasInstalados {

    $BackupPath = Obtener-CarpetaBackup

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
        "Se exportará el listado de programas instalados en la carpeta:`n$BackupPath`n`n¿Desea continuar?",
        "Backup programas instalados",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    $ruta = Join-Path $BackupPath "ProgramasInstalados.txt"

    try {
        $programas = @()

        $rutasRegistro = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        foreach ($rutaRegistro in $rutasRegistro) {
            $programas += Get-ItemProperty $rutaRegistro -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName } |
                Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
        }

        $programas |
            Sort-Object DisplayName -Unique |
            Format-Table -AutoSize |
            Out-File $ruta -Encoding UTF8

        [System.Windows.Forms.MessageBox]::Show(
            "Backup guardado en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo exportar el listado de programas instalados.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

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

    Crear-BotonBackup "Backup listado de programas instalados" 315 {
        Exportar-ProgramasInstalados
    }

    Crear-BotonBackup "Credenciales de Windows" 370 {
        Abrir-CredencialesWindows
    }
    Crear-BotonBackup "Backup de drivers" 425 {
    Exportar-Drivers
}

Crear-BotonBackup "Listado de drivers instalados" 480 {
    Exportar-ListaDrivers
}

    [void]$formBackup.ShowDialog()
}
