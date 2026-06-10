Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = "Pellati Toolkit"
$form.Width = 800
$form.Height = 600
$form.StartPosition = "CenterScreen"

[void]$form.ShowDialog()