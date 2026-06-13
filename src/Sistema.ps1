function Abrir-SeguridadWindows {
    Start-Process "windowsdefender://threat/"
}
function Abrir-IconosEscritorio {
    Start-Process "rundll32.exe" -ArgumentList "shell32.dll,Control_RunDLL desk.cpl,,0"
}
function Abrir-AppsInicio {
    taskmgr.exe /3
}