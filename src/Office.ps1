function Ejecutar-Office {
    param(
        [string]$Ruta,
        [string]$NombreOffice
    )

    if (-not (Test-Path $Ruta)) {

        [System.Windows.Forms.MessageBox]::Show(
            "No se encontró:`n$Ruta",
            "Pellati-Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )

        return
    }

    $respuesta = [System.Windows.Forms.MessageBox]::Show(
@"
Se iniciará la instalación de:

$NombreOffice

¿Desea continuar?
"@,
        "Instalar Office",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    Start-Process $Ruta
}

function Mostrar-Office {

    $formOffice = New-Object System.Windows.Forms.Form
    $formOffice.Text = "Office"
    $formOffice.ClientSize = New-Object System.Drawing.Size(420,430)
    $formOffice.StartPosition = "CenterScreen"
    $formOffice.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

    function Crear-BotonOffice {
        param(
            [string]$Texto,
            [int]$Y,
            [scriptblock]$Accion
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Texto
        $btn.Size = New-Object System.Drawing.Size(300,35)

        $x = [int](($formOffice.ClientSize.Width - $btn.Width) / 2)
        $btn.Location = New-Object System.Drawing.Point($x,$Y)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $btn.Add_Click($Accion)

        $formOffice.Controls.Add($btn)
    }

        Crear-BotonOffice "Office 2013 Pro Retail Español x64" 40 {
        Ejecutar-Office `
            (Join-Path $PSScriptRoot "..\tools\Office\2013-pro-retail-es\setupprofessionalretail.x64.es-es_.exe") `
            "Office 2013 Pro Retail Español x64"
    }

    Crear-BotonOffice "Office 2016 Pro Retail Español x64" 95 {
        Ejecutar-Office `
            (Join-Path $PSScriptRoot "..\tools\Office\2016-pro-retail-es\OfficeSetup.exe") `
            "Office 2016 Pro Retail Español x64"
    }

    Crear-BotonOffice "Office 2019 Pro Retail Español x64" 150 {
        Ejecutar-Office `
            (Join-Path $PSScriptRoot "..\tools\Office\2019-pro-retail-es\OfficeSetup.exe") `
            "Office 2019 Pro Retail Español x64"
    }

    Crear-BotonOffice "Office 2021 Pro Retail Español x64" 205 {
        Ejecutar-Office `
            (Join-Path $PSScriptRoot "..\tools\Office\2021-pro-retail-es\OfficeSetup.exe") `
            "Office 2021 Pro Retail Español x64"
    }

    Crear-BotonOffice "Office 2024 Pro Retail Español x64" 260 {
        Ejecutar-Office `
            (Join-Path $PSScriptRoot "..\tools\Office\2024-pro-retail-es\OfficeSetup.exe") `
            "Office 2024 Pro Retail Español x64"
    }

    Crear-BotonOffice "Microsoft 365 Pro Plus Español x64" 315 {
        Ejecutar-Office `
            (Join-Path $PSScriptRoot "..\tools\Office\365-pro-plus-retail-es\OfficeSetup.exe") `
            "Microsoft 365 Pro Plus Español x64"
    }

    [void]$formOffice.ShowDialog()
}