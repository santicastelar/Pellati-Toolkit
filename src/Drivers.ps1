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

function Abrir-AdministradorDispositivosDrivers {
    Start-Process "devmgmt.msc"
}

function Exportar-Drivers {

    $BackupPath = Obtener-CarpetaBackup
    $Destino = Join-Path $BackupPath "Drivers"

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
        "Se exportarán los drivers del equipo en la carpeta:`n$Destino`n`n¿Desea continuar?",
        "Backup de drivers",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    if (!(Test-Path $Destino)) {
        New-Item -ItemType Directory -Path $Destino | Out-Null
    }

    try {
        Start-Process dism.exe -ArgumentList "/online /export-driver /destination:`"$Destino`"" -Wait -Verb RunAs

        [System.Windows.Forms.MessageBox]::Show(
            "Backup de drivers guardado en:`n$Destino",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo exportar el backup de drivers.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Exportar-ListaDrivers {

    $BackupPath = Obtener-CarpetaBackup
    $ruta = Join-Path $BackupPath "ListaDrivers.txt"

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
        "Se exportará el listado de drivers instalados en la carpeta:`n$BackupPath`n`n¿Desea continuar?",
        "Lista de drivers",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    try {
        driverquery /v /fo list | Out-File $ruta -Encoding UTF8

        [System.Windows.Forms.MessageBox]::Show(
            "Listado de drivers guardado en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo exportar el listado de drivers.",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Mostrar-Drivers {

    $formDrivers = New-Object System.Windows.Forms.Form
    $formDrivers.Text = "Drivers"
    $formDrivers.ClientSize = New-Object System.Drawing.Size(420,330)
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

    Crear-BotonDrivers "Administrador de dispositivos" 95 {
        Abrir-AdministradorDispositivosDrivers
    }

    Crear-BotonDrivers "Backup de drivers" 150 {
        Exportar-Drivers
    }

    Crear-BotonDrivers "Listado de drivers instalados" 205 {
        Exportar-ListaDrivers
    }

    [void]$formDrivers.ShowDialog()
}