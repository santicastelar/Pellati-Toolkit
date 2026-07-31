function Ejecutar-EnBackground {
    param([scriptblock]$ScriptBlock)
    
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    $ps.AddScript($ScriptBlock) | Out-Null
    $handle = $ps.BeginInvoke()
    
    # Opcional: Puedes guardar el handle si quieres controlar cuando termina
    return $handle
}

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

function Optimizar-Servicios {

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
Esta acción detendrá y deshabilitará los siguientes servicios:

• SysMain
• BITS

BITS es utilizado por Windows Update, Microsoft Store y algunas aplicaciones para realizar descargas en segundo plano.

¿Desea continuar?
"@,
        "Optimizar servicios",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    $servicios = @(
        "SysMain",
        "BITS"
    )

    $resultado = @()

    foreach ($nombreServicio in $servicios) {

        $servicio = Get-Service -Name $nombreServicio -ErrorAction SilentlyContinue

        if (-not $servicio) {
            $resultado += "$($nombreServicio): No se encontró."
            continue
        }

        try {

            if ($servicio.Status -ne "Stopped") {
                Stop-Service `
                    -Name $nombreServicio `
                    -Force `
                    -ErrorAction Stop
            }

            Set-Service `
                -Name $nombreServicio `
                -StartupType Disabled `
                -ErrorAction Stop

            $resultado += "$($nombreServicio): Detenido y deshabilitado correctamente."

        }
        catch {

            $resultado += "$($nombreServicio): Error - $($_.Exception.Message)"

        }
    }

    [System.Windows.Forms.MessageBox]::Show(
        ($resultado -join "`r`n"),
        "Optimización finalizada",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}
function Programar-PuntoRestauracionDiario {

    $nombreTarea = "Pellati-Toolkit - Punto de restauracion diario"
    $carpetaScript = "C:\ProgramData\Pellati-Toolkit"
    $rutaScript = Join-Path $carpetaScript "CrearPuntoRestauracion.ps1"

    $mensaje = @"
Se aplicará la siguiente configuración:

1. Se habilitará la Protección del sistema en el disco C:.
2. Se reservará hasta un 10 % del disco C: para puntos de restauración.
3. El servicio Instantáneas de volumen (VSS) quedará configurado en inicio manual.
4. El servicio VSS será iniciado.
5. Se creará una tarea programada que intentará generar un punto de restauración todos los días a las 10:00.
6. La tarea se ejecutará con privilegios elevados, aunque ningún usuario haya iniciado sesión.

Nombre de la tarea:

$nombreTarea

Importante:

Los puntos de restauración no reemplazan un backup completo de los archivos personales.

¿Desea continuar?
"@

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
        $mensaje,
        "Programar punto de restauración diario",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    try {

        # Comprobar administrador
        $identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identidad)

        $esAdministrador = $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )

        if (-not $esAdministrador) {
            throw "Esta función requiere ejecutar Pellati-Toolkit como administrador."
        }

        # Comprobar versión cliente de Windows
        $sistema = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop

        if ($sistema.ProductType -ne 1) {
            throw "Esta función está diseñada para Windows 10 y Windows 11 de escritorio."
        }

        # Crear carpeta del script auxiliar
        if (-not (Test-Path $carpetaScript -PathType Container)) {
            New-Item `
                -Path $carpetaScript `
                -ItemType Directory `
                -Force `
                -ErrorAction Stop |
                Out-Null
        }

        # Habilitar Protección del sistema
        Enable-ComputerRestore `
            -Drive "C:\" `
            -ErrorAction Stop

        # Configurar espacio máximo para las instantáneas
        $procesoVssAdmin = Start-Process `
            -FilePath "vssadmin.exe" `
            -ArgumentList "Resize ShadowStorage /For=C: /On=C: /MaxSize=10%" `
            -Wait `
            -PassThru `
            -WindowStyle Hidden

        if ($procesoVssAdmin.ExitCode -ne 0) {
            throw "No se pudo configurar el espacio reservado para los puntos de restauración."
        }

        # Configurar e iniciar VSS
        Set-Service `
            -Name "VSS" `
            -StartupType Manual `
            -ErrorAction Stop

        $servicioVss = Get-Service -Name "VSS" -ErrorAction Stop

        if ($servicioVss.Status -ne "Running") {
            Start-Service -Name "VSS" -ErrorAction Stop
        }

        # Contenido del script que ejecutará la tarea programada
        $contenidoScript = @'
$ErrorActionPreference = "Stop"

$logFolder = "C:\ProgramData\Pellati-Toolkit"
$logPath = Join-Path $logFolder "PuntosRestauracion.log"

try {
    if (-not (Test-Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }

    Set-Service -Name "VSS" -StartupType Manual -ErrorAction Stop

    $servicioVss = Get-Service -Name "VSS" -ErrorAction Stop

    if ($servicioVss.Status -ne "Running") {
        Start-Service -Name "VSS" -ErrorAction Stop
    }

    Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop

    $descripcion = "Pellati-Toolkit - Punto diario - $(Get-Date -Format 'dd-MM-yyyy HH:mm')"

    Checkpoint-Computer `
        -Description $descripcion `
        -RestorePointType "MODIFY_SETTINGS" `
        -ErrorAction Stop

    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - Punto de restauración creado correctamente." |
        Out-File -FilePath $logPath -Append -Encoding UTF8
}
catch {
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - ERROR: $($_.Exception.Message)" |
        Out-File -FilePath $logPath -Append -Encoding UTF8

    exit 1
}
'@

        $contenidoScript |
            Set-Content `
                -Path $rutaScript `
                -Encoding UTF8 `
                -Force `
                -ErrorAction Stop

        # Crear acción
        $accion = New-ScheduledTaskAction `
            -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$rutaScript`""

        # Ejecutar todos los días a las 10:00
        $desencadenador = New-ScheduledTaskTrigger `
            -Daily `
            -At "10:00"

        # Ejecutar como SYSTEM y con privilegios elevados
        $principalTarea = New-ScheduledTaskPrincipal `
            -UserId "SYSTEM" `
            -LogonType ServiceAccount `
            -RunLevel Highest

        # Configuración apropiada también para notebooks
        $configuracion = New-ScheduledTaskSettingsSet `
            -StartWhenAvailable `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -ExecutionTimeLimit (New-TimeSpan -Minutes 15)

        # Registrar o reemplazar la tarea
        Register-ScheduledTask `
            -TaskName $nombreTarea `
            -Action $accion `
            -Trigger $desencadenador `
            -Principal $principalTarea `
            -Settings $configuracion `
            -Description "Crea diariamente un punto de restauración de Windows mediante Pellati-Toolkit." `
            -Force `
            -ErrorAction Stop |
            Out-Null

        [System.Windows.Forms.MessageBox]::Show(
@"
La tarea fue configurada correctamente.

Horario:
Todos los días a las 10:00

Protección del sistema:
Habilitada en C:

Espacio máximo reservado:
10 % del disco C:

Servicio VSS:
Iniciado y configurado en Manual

Nombre de la tarea:
$nombreTarea

Registro de resultados:
C:\ProgramData\Pellati-Toolkit\PuntosRestauracion.log
"@,
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo configurar la tarea.`n`nDetalle:`n$($_.Exception.Message)",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
function Mostrar-Herramientas {
    $formHerramientas = New-Object System.Windows.Forms.Form
    $formHerramientas.Text = "Herramientas"
    $formHerramientas.ClientSize = New-Object System.Drawing.Size(420,450)
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

    # ==================== BOTÓN ACTIVACIÓN ====================
    Crear-BotonHerramientas "Activar Windows / Office" 40 {
        $formHerramientas.Enabled = $false
        
        Ejecutar-EnBackground {
            try {
                irm https://get.activated.win | iex
                
                [System.Windows.Forms.MessageBox]::Show(
                    "Proceso de activación finalizado.`nRevisa la ventana de PowerShell para ver los detalles.",
                    "Activación Completada",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "Error durante la activación:`n$($_.Exception.Message)",
                    "Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        }
        
        # Reactivamos inmediatamente (el proceso corre en segundo plano)
        $formHerramientas.Enabled = $true
    }

    Crear-BotonHerramientas "Telemetría" 95 {
        Abrir-Telemetria
    }

    Crear-BotonHerramientas "Optimizar servicios" 150 {
        Optimizar-Servicios
    }
        Crear-BotonHerramientas "Backup Outlook (mailpv)" 205    {
        $formHerramientas.Enabled = $false
        Crear-Backup-MPV
        $formHerramientas.Enabled = $true
    }

    Crear-BotonHerramientas "Driver Store Explorer (Rapr)" 315 {
    Abrir-Rapr
}
Crear-BotonHerramientas "Punto de restauración diario" 260 {
    Programar-PuntoRestauracionDiario
}
function Abrir-Rapr {

    $ruta = Join-Path $ToolsPath "Rapr\Rapr.exe"

    if (Test-Path $ruta) {

        Start-Process $ruta

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
function Crear-Backup-MPV {
    $mensaje = "Se va a hacer una excepción en el antivirus Windows Defender.`n`n" +
               "Si tiene otro antivirus (Avast, Kaspersky, ESET, etc.), desactívelo manualmente.`n`n" +
               "⚠️ mailpv.exe se abrirá automáticamente.`n`n" +
               "→ Para guardar las cuentas: presiona el botón de disquete o ve a File → Save"

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
        $mensaje,
        "Pellati-Toolkit - Backup Outlook",
        [System.Windows.Forms.MessageBoxButtons]::OKCancel,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
   
    if ($respuesta -ne "OK") { return }

    try {
        $nombreEquipo = $env:COMPUTERNAME
        $rutaEscritorio = [Environment]::GetFolderPath("Desktop")
        $carpetaBackup = Join-Path $rutaEscritorio "Pellati-Backup-$nombreEquipo"
       
        if (-not (Test-Path $carpetaBackup)) {
            New-Item -Path $carpetaBackup -ItemType Directory -Force | Out-Null
        }

        $rutaMailPV = Join-Path $carpetaBackup "mailpv.exe"
        $rutaZip = "C:\Users\RX580\Desktop\Proyectos\Pellati-Toolkit\tools\MPV\mpv.zip"
       
        if (-not (Test-Path $rutaZip)) {
            [System.Windows.Forms.MessageBox]::Show("No se encontró mpv.zip", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        Write-Host "Agregando excepciones..." -ForegroundColor Yellow
       
        Add-MpPreference -ExclusionPath $carpetaBackup -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionPath $rutaMailPV -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionProcess "mailpv.exe" -ErrorAction SilentlyContinue
       
        Start-Sleep -Seconds 2

        Expand-Archive -Path $rutaZip -DestinationPath $carpetaBackup -Force

        if (Test-Path $rutaMailPV) {
            [System.Windows.Forms.MessageBox]::Show(
                "✅ Programa abierto.`n`nGuarda las cuentas manualmente usando el botón de disquete.",
                "Mail PassView Iniciado",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
           
            Start-Process "explorer.exe" $carpetaBackup
            Start-Sleep -Seconds 1
            Start-Process -FilePath $rutaMailPV
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("No se encontró mailpv.exe", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}
    [void]$formHerramientas.ShowDialog()
}