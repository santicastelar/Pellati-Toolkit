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
    $formBackup.ClientSize = New-Object System.Drawing.Size(420,750)
    $formBackup.StartPosition = "CenterScreen"
    $formBackup.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)
function Exportar-ImpresorasInstaladas {

    $BackupPath = Obtener-CarpetaBackup

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
Se exportará el listado de impresoras instaladas en la carpeta:

$BackupPath

El backup incluirá:

- Nombre de la impresora
- Controlador
- Puerto
- Estado
- Impresora compartida
- Nombre compartido
- Impresora predeterminada

¿Desea continuar?
"@,
        "Backup impresoras instaladas",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    $ruta = Join-Path $BackupPath "ImpresorasInstaladas.txt"

    try {
        $impresoras = @(Get-Printer -ErrorAction Stop)

        $contenido = @()
        $contenido += "BACKUP IMPRESORAS INSTALADAS"
        $contenido += "============================"
        $contenido += ""
        $contenido += "Equipo: $env:COMPUTERNAME"
        $contenido += "Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        $contenido += ""

        if ($impresoras.Count -eq 0) {
            $contenido += "No se encontraron impresoras instaladas."
        }
        else {
            foreach ($impresora in $impresoras) {

                $esPredeterminada = "No"

                try {
                    $predeterminada = Get-CimInstance `
                        -ClassName Win32_Printer `
                        -Filter "Name='$($impresora.Name.Replace("'", "''"))'" `
                        -ErrorAction Stop

                    if ($predeterminada.Default) {
                        $esPredeterminada = "Sí"
                    }
                }
                catch {
                    $esPredeterminada = "No se pudo determinar"
                }

                $compartida = if ($impresora.Shared) {
                    "Sí"
                }
                else {
                    "No"
                }

                $nombreCompartido = if (
                    [string]::IsNullOrWhiteSpace($impresora.ShareName)
                ) {
                    "No corresponde"
                }
                else {
                    $impresora.ShareName
                }

                $contenido += "Nombre: $($impresora.Name)"
                $contenido += "Controlador: $($impresora.DriverName)"
                $contenido += "Puerto: $($impresora.PortName)"
                $contenido += "Estado: $($impresora.PrinterStatus)"
                $contenido += "Compartida: $compartida"
                $contenido += "Nombre compartido: $nombreCompartido"
                $contenido += "Predeterminada: $esPredeterminada"
                $contenido += ""
                $contenido += "----------------------------------------"
                $contenido += ""
            }
        }

        $contenido | Out-File $ruta -Encoding UTF8

        [System.Windows.Forms.MessageBox]::Show(
            "Backup guardado en:`n$ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudieron obtener las impresoras instaladas.`n`n$($_.Exception.Message)",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
function Exportar-FirmasOutlook {

    $BackupPath = Obtener-CarpetaBackup
    $rutaMicrosoft = Join-Path $env:APPDATA "Microsoft"

    $rutasPosibles = @(
        (Join-Path $rutaMicrosoft "Signatures"),
        (Join-Path $rutaMicrosoft "Firmas")
    )

    $carpetasEncontradas = @(
        $rutasPosibles | Where-Object {
            Test-Path $_ -PathType Container
        }
    )

    if ($carpetasEncontradas.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
@"
No se encontró ninguna carpeta de firmas de Outlook.

Se revisaron las siguientes rutas:

$($rutasPosibles -join "`n")

Es posible que Outlook no tenga firmas configuradas para este usuario.
"@,
            "Backup de firmas de Outlook",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        return
    }

    $nombresEncontrados = @(
        $carpetasEncontradas | ForEach-Object {
            Split-Path $_ -Leaf
        }
    )

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
Se realizará el backup completo de las firmas de Outlook.

Carpetas encontradas:

$($nombresEncontrados -join "`n")

El respaldo se guardará en:

$BackupPath\Firmas_Outlook

¿Desea continuar?
"@,
        "Backup de firmas de Outlook",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    $destinoPrincipal = Join-Path $BackupPath "Firmas_Outlook"

    try {
        if (-not (Test-Path $destinoPrincipal)) {
            New-Item `
                -Path $destinoPrincipal `
                -ItemType Directory `
                -Force |
                Out-Null
        }

        foreach ($carpetaOrigen in $carpetasEncontradas) {

            $nombreCarpeta = Split-Path $carpetaOrigen -Leaf
            $carpetaDestino = Join-Path $destinoPrincipal $nombreCarpeta

            if (Test-Path $carpetaDestino) {
                Remove-Item `
                    -Path $carpetaDestino `
                    -Recurse `
                    -Force `
                    -ErrorAction Stop
            }

            Copy-Item `
                -Path $carpetaOrigen `
                -Destination $destinoPrincipal `
                -Recurse `
                -Force `
                -ErrorAction Stop
        }

        $rutaInforme = Join-Path $destinoPrincipal "Informacion_Backup.txt"

        $contenido = @()
        $contenido += "BACKUP DE FIRMAS DE OUTLOOK"
        $contenido += "============================"
        $contenido += ""
        $contenido += "Usuario: $env:USERNAME"
        $contenido += "Equipo: $env:COMPUTERNAME"
        $contenido += "Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        $contenido += ""
        $contenido += "Carpetas respaldadas:"

        foreach ($carpeta in $carpetasEncontradas) {
            $contenido += "- $carpeta"
        }

        $contenido |
            Out-File `
                -FilePath $rutaInforme `
                -Encoding UTF8

        [System.Windows.Forms.MessageBox]::Show(
@"
El backup de las firmas de Outlook se realizó correctamente.

Ubicación:

$destinoPrincipal
"@,
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
@"
No se pudo realizar el backup de las firmas de Outlook.

$($_.Exception.Message)
"@,
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
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

Crear-BotonBackup "Backup impresoras instaladas" 535 {
    Exportar-ImpresorasInstaladas
}

Crear-BotonBackup "Backup firmas de Outlook" 590 {
    Exportar-FirmasOutlook
}

Crear-BotonBackup "Backup Google Chrome" 645 {
    Mostrar-BackupChrome
}

    [void]$formBackup.ShowDialog()
}
