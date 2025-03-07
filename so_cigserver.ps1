# cigserver-service.ps1 - Version 1.06
# Check for admin rights
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Administrator privileges required. Exiting."
    Exit 1
}
# Install NSSM via winget
winget install --id NSSM.NSSM -e --accept-package-agreements --accept-source-agreements
Start-Sleep -Seconds 5
# Set NSSM path (detect dynamically)
$nssmPaths = @(
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links\nssm.exe",
    "C:\Program Files\NSSM\nssm.exe",
    "C:\Program Files (x86)\NSSM\nssm.exe"
)
$nssmPath = $nssmPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-Not $nssmPath) {
    Write-Error "NSSM not found. Exiting."
    Exit 1
}
# Ensure EXE exists before proceeding
$exePath = "C:\Program Files (x86)\StationMaster\cigserver.exe"
$startupDir = "C:\Program Files (x86)\StationMaster"
if (-Not (Test-Path $exePath)) {
    Write-Error "Executable not found: $exePath. Exiting."
    Exit 1
}
# Install cigserver.exe as a service
$serviceName = "SO CigServer"
$displayName = "SO CigServer"
$currentUser = "$env:USERDOMAIN\$env:USERNAME"
$password = Read-Host "Enter password for $currentUser" -AsSecureString
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
& $nssmPath install $serviceName $exePath
& $nssmPath set $serviceName AppDirectory "$startupDir"
& $nssmPath set $serviceName Start SERVICE_AUTO_START
& $nssmPath set $serviceName DisplayName "$displayName"
& $nssmPath set $serviceName Description "Keeps cigserver.exe running."
& $nssmPath set $serviceName ObjectName "$currentUser" "$plainPassword"
# NSSM auto-restart settings
& $nssmPath set $serviceName AppExit Default Restart
& $nssmPath set $serviceName AppRestartDelay 5000
# Windows service recovery options
sc.exe failure $serviceName reset= 86400 actions= restart/5000/restart/5000/restart/5000
# Wait a moment before starting
Start-Sleep -Seconds 2
# Start the service
Start-Service -Name $serviceName
