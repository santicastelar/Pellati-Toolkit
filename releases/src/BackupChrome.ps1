function Obtener-RutaChrome {
    $rutas = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    foreach ($r in $rutas) { if (Test-Path $r) { return $r } }
    return $null
}

function Obtener-CarpetaBackup {
    $nombreEquipo = $env:COMPUTERNAME
    $escritorio = [Environment]::GetFolderPath("Desktop")
    $carpeta = Join-Path $escritorio "Pellati-Backup-$nombreEquipo"
    if (-not (Test-Path $carpeta)) { New-Item -Path $carpeta -ItemType Directory | Out-Null }
    return $carpeta
}

function Mostrar-BackupChrome {
    $rutaChrome = Obtener-RutaChrome
    if (-not $rutaChrome) {
        [System.Windows.Forms.MessageBox]::Show('Google Chrome no se encuentra instalado.', 'Pellati-Toolkit', 'OK', 'Warning')
        return
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Backup Google Chrome'
    $form.ClientSize = New-Object System.Drawing.Size(440, 380)
    $form.StartPosition = 'CenterScreen'
    $form.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonChrome {
        param([string]$Texto, [int]$Y, [scriptblock]$Accion)
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $Texto
        $b.Size = New-Object System.Drawing.Size(320, 38)
        $b.Location = New-Object System.Drawing.Point(60, $Y)
        $b.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $b.Add_Click($Accion)
        $form.Controls.Add($b)
    }

    Crear-BotonChrome 'Información completa del perfil' 30 { Exportar-InformacionChrome }
    Crear-BotonChrome 'Backup de Marcadores (HTML + JSON)' 80 { Exportar-MarcadoresChrome }
    Crear-BotonChrome 'Exportar Contraseñas' 130 { Abrir-GestorContrasenas }
    Crear-BotonChrome 'Estado de Sincronización' 180 { Mostrar-EstadoSincronizacion }
    Crear-BotonChrome 'Backup completo de Chrome' 230 { Backup-CompletoPerfil }

    [void]$form.ShowDialog()
}
# ==================== FUNCIONES AUXILIARES ====================

function Obtener-PerfilesChrome {
    $userData = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data"
    $localState = Join-Path $userData "Local State"
    $perfiles = @()

    if (Test-Path $localState) {
        try {
            $json = Get-Content -Path $localState -Raw -Encoding UTF8 |
                ConvertFrom-Json

            foreach ($propiedad in $json.profile.info_cache.PSObject.Properties) {
                $carpetaPerfil = $propiedad.Name
                $datosPerfil = $propiedad.Value
                $rutaPerfil = Join-Path $userData $carpetaPerfil

                if (Test-Path $rutaPerfil) {
                    $perfiles += [PSCustomObject]@{
                        Carpeta    = $carpetaPerfil
                        Nombre     = if ($datosPerfil.name) {
                            $datosPerfil.name
                        } else {
                            $carpetaPerfil
                        }
                        Email      = $datosPerfil.user_name
                        Gestionado = $datosPerfil.is_managed
                        Ruta       = $rutaPerfil
                    }
                }
            }
        }
        catch {
            Write-Warning "No se pudo leer Local State: $($_.Exception.Message)"
        }
    }

    # Respaldo por si Local State no contiene correctamente los perfiles
    if ($perfiles.Count -eq 0 -and (Test-Path $userData)) {
        $carpetas = Get-ChildItem -Path $userData -Directory |
            Where-Object {
                $_.Name -eq "Default" -or
                $_.Name -match "^Profile \d+$"
            }

        foreach ($carpeta in $carpetas) {
            $perfiles += [PSCustomObject]@{
                Carpeta    = $carpeta.Name
                Nombre     = $carpeta.Name
                Email      = ""
                Gestionado = $false
                Ruta       = $carpeta.FullName
            }
        }
    }

    return $perfiles
}

function Convertir-TextoHtml {
    param(
        [AllowNull()]
        [string]$Texto
    )

    if ($null -eq $Texto) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode($Texto)
}

function Convertir-FechaChrome {
    param(
        [AllowNull()]
        [string]$FechaChrome
    )

    if ([string]::IsNullOrWhiteSpace($FechaChrome)) {
        return [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    }

    try {
        # Chrome guarda el tiempo en microsegundos desde 01/01/1601.
        $microsegundos = [Int64]$FechaChrome
        $fechaBase = [DateTime]::SpecifyKind(
            [DateTime]"1601-01-01 00:00:00",
            [DateTimeKind]::Utc
        )

        $fecha = $fechaBase.AddTicks($microsegundos * 10)
        return [DateTimeOffset]$fecha |
            ForEach-Object { $_.ToUnixTimeSeconds() }
    }
    catch {
        return [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    }
}

function Convertir-NodoMarcadoresAHtml {
    param(
        [Parameter(Mandatory)]
        $Nodo,

        [Parameter(Mandatory)]
        [System.Text.StringBuilder]$Constructor,

        [int]$Nivel = 1
    )

    $sangria = "    " * $Nivel

    if ($Nodo.type -eq "url") {
        $nombre = Convertir-TextoHtml $Nodo.name
        $url = Convertir-TextoHtml $Nodo.url
        $fecha = Convertir-FechaChrome $Nodo.date_added

        [void]$Constructor.AppendLine(
            "$sangria<DT><A HREF=`"$url`" ADD_DATE=`"$fecha`">$nombre</A>"
        )

        return
    }

    if ($Nodo.type -eq "folder") {
        $nombreCarpeta = Convertir-TextoHtml $Nodo.name
        $fechaCarpeta = Convertir-FechaChrome $Nodo.date_added

        [void]$Constructor.AppendLine(
            "$sangria<DT><H3 ADD_DATE=`"$fechaCarpeta`">$nombreCarpeta</H3>"
        )

        [void]$Constructor.AppendLine("$sangria<DL><p>")

        if ($Nodo.children) {
            foreach ($hijo in $Nodo.children) {
                Convertir-NodoMarcadoresAHtml `
                    -Nodo $hijo `
                    -Constructor $Constructor `
                    -Nivel ($Nivel + 1)
            }
        }

        [void]$Constructor.AppendLine("$sangria</DL><p>")
    }
}

function Convertir-BookmarksJsonAHtml {
    param(
        [Parameter(Mandatory)]
        [string]$ArchivoBookmarks,

        [Parameter(Mandatory)]
        [string]$ArchivoHtml
    )

    try {
        $json = Get-Content -Path $ArchivoBookmarks -Raw -Encoding UTF8 |
            ConvertFrom-Json

        $constructor = New-Object System.Text.StringBuilder

        [void]$constructor.AppendLine(
            '<!DOCTYPE NETSCAPE-Bookmark-file-1>'
        )
        [void]$constructor.AppendLine(
            '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">'
        )
        [void]$constructor.AppendLine(
            '<TITLE>Marcadores de Google Chrome</TITLE>'
        )
        [void]$constructor.AppendLine(
            '<H1>Marcadores de Google Chrome</H1>'
        )
        [void]$constructor.AppendLine('<DL><p>')

        $raices = @(
            @{
                Propiedad = "bookmark_bar"
                Nombre    = "Barra de marcadores"
            },
            @{
                Propiedad = "other"
                Nombre    = "Otros marcadores"
            },
            @{
                Propiedad = "synced"
                Nombre    = "Marcadores de dispositivos"
            }
        )

        foreach ($raiz in $raices) {
            $propiedad = $raiz.Propiedad
            $nodoRaiz = $json.roots.$propiedad

            if ($null -ne $nodoRaiz) {
                # Reemplaza el nombre interno por uno más claro.
                $nodoRaiz.name = $raiz.Nombre

                Convertir-NodoMarcadoresAHtml `
                    -Nodo $nodoRaiz `
                    -Constructor $constructor `
                    -Nivel 1
            }
        }

        [void]$constructor.AppendLine('</DL><p>')

        [System.IO.File]::WriteAllText(
            $ArchivoHtml,
            $constructor.ToString(),
            [System.Text.UTF8Encoding]::new($false)
        )

        return $true
    }
    catch {
        Write-Warning "No se pudo convertir el archivo de marcadores: $($_.Exception.Message)"
        return $false
    }
}


# ==================== INFORMACIÓN DE PERFILES ====================

function Exportar-InformacionChrome {
    $carpetaBackup = Obtener-CarpetaBackup
    $archivo = Join-Path $carpetaBackup "Info_Perfiles_Chrome.txt"
    $perfiles = @(Obtener-PerfilesChrome)

    $lineas = New-Object System.Collections.Generic.List[string]

    $lineas.Add("=== INFORMACIÓN DE PERFILES DE GOOGLE CHROME ===")
    $lineas.Add("Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')")
    $lineas.Add("Equipo: $env:COMPUTERNAME")
    $lineas.Add("Usuario de Windows: $env:USERNAME")
    $lineas.Add("")
    $lineas.Add("Cantidad de perfiles encontrados: $($perfiles.Count)")
    $lineas.Add("")

    if ($perfiles.Count -eq 0) {
        $lineas.Add("No se encontraron perfiles de Google Chrome.")
    }
    else {
        foreach ($perfil in $perfiles) {
            $lineas.Add("--------------------------------------------")
            $lineas.Add("Nombre visible: $($perfil.Nombre)")
            $lineas.Add("Carpeta interna: $($perfil.Carpeta)")
            $lineas.Add("Ruta: $($perfil.Ruta)")

            if (-not [string]::IsNullOrWhiteSpace($perfil.Email)) {
                $lineas.Add("Correo electrónico: $($perfil.Email)")
            }
            else {
                $lineas.Add("Correo electrónico: No disponible")
            }

            $gestionado = if ($perfil.Gestionado -eq $true) {
                "Sí"
            } else {
                "No"
            }

            $lineas.Add("Perfil gestionado: $gestionado")

            $archivoBookmarks = Join-Path $perfil.Ruta "Bookmarks"
            $tieneMarcadores = if (Test-Path $archivoBookmarks) {
                "Sí"
            } else {
                "No"
            }

            $lineas.Add("Archivo de marcadores: $tieneMarcadores")
            $lineas.Add("")
        }
    }

    $lineas |
        Out-File -FilePath $archivo -Encoding UTF8 -Force

    [System.Windows.Forms.MessageBox]::Show(
        "Se exportó la información de $($perfiles.Count) perfil(es).`n`n$archivo",
        "Información de Chrome",
        "OK",
        "Information"
    )
}


# ==================== EXPORTACIÓN DE MARCADORES ====================

function Exportar-MarcadoresChrome {
    $carpetaBackup = Obtener-CarpetaBackup
    $carpetaMarcadores = Join-Path $carpetaBackup "Marcadores_Chrome"
    $perfiles = @(Obtener-PerfilesChrome)

    if (-not (Test-Path $carpetaMarcadores)) {
        New-Item `
            -Path $carpetaMarcadores `
            -ItemType Directory `
            -Force |
            Out-Null
    }

    if ($perfiles.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontraron perfiles de Google Chrome.",
            "Marcadores",
            "OK",
            "Warning"
        )
        return
    }

    $exportados = 0
    $sinMarcadores = New-Object System.Collections.Generic.List[string]

    foreach ($perfil in $perfiles) {
        $archivoOrigen = Join-Path $perfil.Ruta "Bookmarks"

        if (-not (Test-Path $archivoOrigen)) {
            $sinMarcadores.Add($perfil.Nombre)
            continue
        }

        $nombreSeguro = $perfil.Nombre -replace '[\\/:*?"<>|]', "_"
        $carpetaSegura = $perfil.Carpeta -replace '[\\/:*?"<>|]', "_"

        $baseNombre = "${nombreSeguro}_${carpetaSegura}"

        $archivoJson = Join-Path `
            $carpetaMarcadores `
            "Bookmarks_${baseNombre}.json"

        $archivoHtml = Join-Path `
            $carpetaMarcadores `
            "Bookmarks_${baseNombre}.html"

        try {
            Copy-Item `
                -Path $archivoOrigen `
                -Destination $archivoJson `
                -Force `
                -ErrorAction Stop

            $resultado = Convertir-BookmarksJsonAHtml `
                -ArchivoBookmarks $archivoOrigen `
                -ArchivoHtml $archivoHtml

            if ($resultado) {
                $exportados++
            }
        }
        catch {
            Write-Warning "Error exportando $($perfil.Nombre): $($_.Exception.Message)"
        }
    }

    if ($exportados -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontraron marcadores para exportar.",
            "Marcadores",
            "OK",
            "Warning"
        )
        return
    }

    $mensaje = @"
Se exportaron los marcadores de $exportados perfil(es).

Se generó para cada perfil:

• Un archivo HTML importable desde Chrome.
• Una copia JSON como respaldo original.

Carpeta:
$carpetaMarcadores
"@

    [System.Windows.Forms.MessageBox]::Show(
        $mensaje,
        "Marcadores exportados",
        "OK",
        "Information"
    )
}


# ==================== CONTRASEÑAS ====================

function Abrir-GestorContrasenas {
    try {
        Start-Process "https://passwords.google.com/"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo abrir el Gestor de contraseñas.`n`n$($_.Exception.Message)",
            "Error",
            "OK",
            "Error"
        )
    }
}
# ==================== ESTADO DE SINCRONIZACIÓN ====================

function Mostrar-EstadoSincronizacion {
    $carpetaBackup = Obtener-CarpetaBackup
    $archivoSalida = Join-Path $carpetaBackup "Estado_Sincronizacion_Chrome.txt"
    $perfiles = @(Obtener-PerfilesChrome)

    $lineas = New-Object System.Collections.Generic.List[string]

    $lineas.Add("=== ESTADO DE SINCRONIZACIÓN DE GOOGLE CHROME ===")
    $lineas.Add("Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')")
    $lineas.Add("Equipo: $env:COMPUTERNAME")
    $lineas.Add("Usuario de Windows: $env:USERNAME")
    $lineas.Add("")

    if ($perfiles.Count -eq 0) {
        $lineas.Add("No se encontraron perfiles de Google Chrome.")
    }
    else {
        foreach ($perfil in $perfiles) {
            $preferencesPath = Join-Path $perfil.Ruta "Preferences"

            $lineas.Add("--------------------------------------------")
            $lineas.Add("Perfil: $($perfil.Nombre)")
            $lineas.Add("Carpeta interna: $($perfil.Carpeta)")

            if (-not [string]::IsNullOrWhiteSpace($perfil.Email)) {
                $lineas.Add("Cuenta asociada: $($perfil.Email)")
            }
            else {
                $lineas.Add("Cuenta asociada: No detectada")
            }

            if (-not (Test-Path $preferencesPath)) {
                $lineas.Add("Estado: No se encontró el archivo Preferences.")
                $lineas.Add("")
                continue
            }

            try {
                $preferences = Get-Content `
                    -Path $preferencesPath `
                    -Raw `
                    -Encoding UTF8 `
                    -ErrorAction Stop |
                    ConvertFrom-Json `
                    -ErrorAction Stop

                $sync = $preferences.sync

                if ($null -eq $sync) {
                    $lineas.Add("Sincronización configurada: No detectada")
                }
                else {
                    $sincronizacionSolicitada = $false

                    if ($sync.requested -eq $true -or
                        $sync.keep_everything_synced -eq $true -or
                        $sync.has_setup_completed -eq $true) {
                        $sincronizacionSolicitada = $true
                    }

                    $lineas.Add(
                        "Sincronización configurada: " +
                        $(if ($sincronizacionSolicitada) { "Sí" } else { "No o no confirmable" })
                    )

                    if ($null -ne $sync.keep_everything_synced) {
                        $lineas.Add(
                            "Sincronizar todos los datos: " +
                            $(if ($sync.keep_everything_synced -eq $true) { "Sí" } else { "No" })
                        )
                    }

                    if ($null -ne $sync.has_setup_completed) {
                        $lineas.Add(
                            "Configuración completada: " +
                            $(if ($sync.has_setup_completed -eq $true) { "Sí" } else { "No" })
                        )
                    }

                    if ($sync.disabled_types) {
                        $tiposDesactivados = @($sync.disabled_types) -join ", "
                        $lineas.Add("Tipos de datos desactivados: $tiposDesactivados")
                    }
                }
            }
            catch {
                $lineas.Add("Estado: No se pudo leer Preferences.")
                $lineas.Add("Detalle: $($_.Exception.Message)")
            }

            $lineas.Add("")
        }
    }

    $lineas |
        Out-File `
            -FilePath $archivoSalida `
            -Encoding UTF8 `
            -Force

    [System.Windows.Forms.MessageBox]::Show(
        "El estado de sincronización se guardó correctamente en:`n`n$archivoSalida",
        "Estado de sincronización",
        "OK",
        "Information"
    )
}


# ==================== BACKUP COMPLETO ====================

function Backup-CompletoPerfil {
    $carpetaBackup = Obtener-CarpetaBackup
    $origen = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data"
    $destino = Join-Path $carpetaBackup "Perfil_Chrome_Backup"

    if (-not (Test-Path $origen)) {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró la carpeta de datos de Google Chrome.`n`n$origen",
            "Backup completo",
            "OK",
            "Warning"
        )
        return
    }

    $procesosChrome = @(Get-Process -Name "chrome" -ErrorAction SilentlyContinue)

    if ($procesosChrome.Count -gt 0) {
        $respuesta = [System.Windows.Forms.MessageBox]::Show(
            "Google Chrome está abierto.`n`nPara copiar correctamente el perfil completo es recomendable cerrarlo.`n`n¿Querés que Pellati-Toolkit cierre Chrome y continúe?",
            "Cerrar Google Chrome",
            "YesNo",
            "Question"
        )

        if ($respuesta -ne "Yes") {
            [System.Windows.Forms.MessageBox]::Show(
                "El backup fue cancelado para evitar una copia incompleta.",
                "Backup cancelado",
                "OK",
                "Information"
            )
            return
        }

        try {
            $procesosChrome |
                Stop-Process -Force -ErrorAction Stop

            Start-Sleep -Seconds 2
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "No se pudo cerrar Google Chrome.`n`n$($_.Exception.Message)",
                "Error",
                "OK",
                "Error"
            )
            return
        }
    }

    try {
        if (Test-Path $destino) {
            Remove-Item `
                -Path $destino `
                -Recurse `
                -Force `
                -ErrorAction Stop
        }

        New-Item `
            -Path $destino `
            -ItemType Directory `
            -Force `
            -ErrorAction Stop |
            Out-Null

        # Robocopy es más confiable que Copy-Item para perfiles grandes.
        $argumentosRobocopy = @(
            $origen,
            $destino,
            "/E",
            "/COPY:DAT",
            "/DCOPY:DAT",
            "/R:2",
            "/W:1",
            "/XJ",
            "/NFL",
            "/NDL",
            "/NP"
        )

        & robocopy @argumentosRobocopy | Out-Null
        $codigoRobocopy = $LASTEXITCODE

        # En Robocopy, los códigos 0 a 7 indican copia correcta
        # o diferencias menores, no un error fatal.
        if ($codigoRobocopy -gt 7) {
            throw "Robocopy finalizó con el código $codigoRobocopy."
        }

        $fechaBackup = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
        $registro = Join-Path $destino "Pellati_Backup_Info.txt"

        @"
Backup completo de Google Chrome
Fecha: $fechaBackup
Equipo: $env:COMPUTERNAME
Usuario: $env:USERNAME
Origen: $origen
Destino: $destino
Código de Robocopy: $codigoRobocopy
"@ |
            Out-File `
                -FilePath $registro `
                -Encoding UTF8 `
                -Force

        [System.Windows.Forms.MessageBox]::Show(
            "El backup completo de Chrome se creó correctamente en:`n`n$destino",
            "Backup completo",
            "OK",
            "Information"
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo completar el backup de Chrome.`n`n$($_.Exception.Message)",
            "Error de backup",
            "OK",
            "Error"
        )
    }
}