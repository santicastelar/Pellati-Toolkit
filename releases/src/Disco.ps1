function Abrir-AdministracionDiscos {
    Start-Process "diskmgmt.msc"
}

function Mostrar-BitLocker {

    $formBitLocker = New-Object System.Windows.Forms.Form
    $formBitLocker.Text = "BitLocker C:"
    $formBitLocker.ClientSize = New-Object System.Drawing.Size(430,260)
    $formBitLocker.StartPosition = "CenterScreen"

    $txtEstado = New-Object System.Windows.Forms.TextBox
    $txtEstado.Multiline = $true
    $txtEstado.ReadOnly = $true
    $txtEstado.ScrollBars = "Vertical"
    $txtEstado.Size = New-Object System.Drawing.Size(360,120)
    $txtEstado.Location = New-Object System.Drawing.Point(35,25)
    $formBitLocker.Controls.Add($txtEstado)

    function Actualizar-EstadoBitLocker {
        try {
            $vol = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop

            $txtEstado.Text = @"
Unidad: $($vol.MountPoint)
Estado: $($vol.VolumeStatus)
Proteccion: $($vol.ProtectionStatus)
Porcentaje cifrado: $($vol.EncryptionPercentage)%
Metodo: $($vol.EncryptionMethod)
"@
        }
        catch {
            $txtEstado.Text = "No se pudo obtener el estado de BitLocker."
        }
    }

    $btnActualizar = New-Object System.Windows.Forms.Button
    $btnActualizar.Text = "Actualizar estado"
    $btnActualizar.Size = New-Object System.Drawing.Size(160,35)
    $btnActualizar.Location = New-Object System.Drawing.Point(35,165)
    $btnActualizar.Add_Click({
        Actualizar-EstadoBitLocker
    })
    $formBitLocker.Controls.Add($btnActualizar)

    $btnDesactivar = New-Object System.Windows.Forms.Button
    $btnDesactivar.Text = "Desactivar BitLocker"
    $btnDesactivar.Size = New-Object System.Drawing.Size(170,35)
    $btnDesactivar.Location = New-Object System.Drawing.Point(225,165)
    $btnDesactivar.Add_Click({

        try {
            $vol = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop

            if ($vol.ProtectionStatus -eq "Off" -and $vol.VolumeStatus -eq "FullyDecrypted") {
                [System.Windows.Forms.MessageBox]::Show(
                    "BitLocker ya esta desactivado en la unidad C:.",
                    "BitLocker",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )

                Actualizar-EstadoBitLocker
                return
            }

            $respuesta = [System.Windows.Forms.MessageBox]::Show(
                "Se desactivara BitLocker en la unidad C: y comenzara el descifrado. Desea continuar?",
                "Confirmar BitLocker",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )

            if ($respuesta -eq [System.Windows.Forms.DialogResult]::Yes) {
                Disable-BitLocker -MountPoint "C:" -ErrorAction Stop
                Actualizar-EstadoBitLocker

                [System.Windows.Forms.MessageBox]::Show(
                    "Se inicio la desactivacion de BitLocker. Use Actualizar estado para ver el progreso.",
                    "BitLocker",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "No se pudo consultar o modificar BitLocker en la unidad C:.",
                "Error BitLocker",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    })
    $formBitLocker.Controls.Add($btnDesactivar)

    Actualizar-EstadoBitLocker

    [void]$formBitLocker.ShowDialog()
}
function Abrir-CrystalDiskInfo {

    $basePath = Join-Path $PSScriptRoot "..\tools\CrystalDiskInfo9_9_1"

    if ([Environment]::Is64BitOperatingSystem) {
        $exe = Join-Path $basePath "DiskInfo64.exe"
    }
    else {
        $exe = Join-Path $basePath "DiskInfo32.exe"
    }

    if (Test-Path $exe) {
        Start-Process $exe
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No se encontro CrystalDiskInfo en:`n$exe",
            "Pellati-Toolkit"
        )
    }
}
function Mostrar-Disco {

    $formDisco = New-Object System.Windows.Forms.Form
    $formDisco.Text = "Disco"
    $formDisco.ClientSize = New-Object System.Drawing.Size(420,250)
    $formDisco.StartPosition = "CenterScreen"
    $formDisco.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonDisco {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($formDisco.ClientSize.Width - $btn.Width) / 2)

        $btn.Location = New-Object System.Drawing.Point($x,$Y)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $formDisco.Controls.Add($btn)
    }

    Crear-BotonDisco "Administración de discos" 40 {
        Abrir-AdministracionDiscos
    }

    Crear-BotonDisco "BitLocker C:" 95 {
        Mostrar-BitLocker
    }
Crear-BotonDisco "CrystalDiskInfo" 150 {
    Abrir-CrystalDiskInfo
}
    [void]$formDisco.ShowDialog()
}