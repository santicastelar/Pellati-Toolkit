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
    # ... (tu función actual sin cambios) ...
    # (mantengo tu código original aquí)
}

function Mostrar-Herramientas {
    $formHerramientas = New-Object System.Windows.Forms.Form
    $formHerramientas.Text = "Herramientas"
    $formHerramientas.ClientSize = New-Object System.Drawing.Size(420,350)
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
        Crear-BotonHerramientas "Backup Outlook (mailpv)" 205 {
        $formHerramientas.Enabled = $false
        Crear-Backup-MPV
        $formHerramientas.Enabled = $true
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