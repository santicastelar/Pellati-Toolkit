function Abrir-AppData {
    Start-Process explorer.exe $env:APPDATA
}

function Abrir-LocalAppData {
    Start-Process explorer.exe $env:LOCALAPPDATA
}
function Abrir-LocalLow {
    Start-Process explorer.exe "$env:USERPROFILE\AppData\LocalLow"
}
function Abrir-ProgramData {
    Start-Process explorer.exe $env:PROGRAMDATA
}

function Abrir-StartupUsuario {
    Start-Process explorer.exe "shell:startup"
}

function Abrir-StartupTodos {
    Start-Process explorer.exe "shell:common startup"
}

function Abrir-TempUsuario {
    Start-Process explorer.exe $env:TEMP
}

function Abrir-TempWindows {
    Start-Process explorer.exe "C:\Windows\Temp"
}
function Mostrar-CarpetasWindows {

    $formCarpetas = New-Object System.Windows.Forms.Form
    $formCarpetas.Text = "Carpetas de Windows"
    $formCarpetas.Size = New-Object System.Drawing.Size(420,550)
    $formCarpetas.StartPosition = "CenterScreen"

   function Crear-BotonCarpeta {
    param(
        [string]$Texto,
        [int]$Y,
        [scriptblock]$Accion
    )

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Texto
    $btn.Size = New-Object System.Drawing.Size(300,35)

    $x = ($formCarpetas.ClientSize.Width - $btn.Width) / 2
    $btn.Location = New-Object System.Drawing.Point($x,$Y)

    $btn.Add_Click($Accion)

    $formCarpetas.Controls.Add($btn)
}

    Crear-BotonCarpeta "Roaming" 40 {
    Abrir-AppData
}

Crear-BotonCarpeta "AppDataLocal" 85 {
    Abrir-LocalAppData
}

Crear-BotonCarpeta "LocalLow" 130 {
    Abrir-LocalLow
}

Crear-BotonCarpeta "ProgramData" 175 {
    Abrir-ProgramData
}

Crear-BotonCarpeta "Startup Usuario" 220 {
    Abrir-StartupUsuario
}

Crear-BotonCarpeta "Startup Todos" 265 {
    Abrir-StartupTodos
}

Crear-BotonCarpeta "Temp Usuario" 310 {
    Abrir-TempUsuario
}

Crear-BotonCarpeta "Temp Windows" 355 {
    Abrir-TempWindows
}

    

    $formCarpetas.ShowDialog()
}