<#
    .SYNOPSIS
    Edits the winCollect agent's Forwarder IP.

    .DESCRIPTION
    Edits the winCollect TXT file and updates the old IP to the new IP.

    .INPUTS
    None.

    .OUTPUTS
    Success or Error message.

    .EXAMPLE
    C:\PS> winCollectMap.ps1
    Success

    .EXAMPLE
    C:\PS> winCollectMap.ps1
    Error message

    .NOTES
    Copyright (c) 2018, Dominique Pizzie
    Copyrights licensed under the MIT License (MIT).
    See the accompanying LICENSE file for terms.

    .LINK
    http://www-01.ibm.com/support/docview.wss?uid=swg21692904
#>

#Requires -Version 3.0
Set-StrictMode -Version Latest

$newIP = 'IP ADDRESS HERE'
$oldIP = 'IP ADDRESS HERE'

# Deafult PATH for winCollect configuration
# "%ProgramFiles%\IBM\WinCollect\config\install_config.txt"
$configPath = "$env:ProgramFiles\IBM\WinCollect\config\"
$configFile = "install_config.txt"
$configPEM = "ConfigurationServer.PEM"

function Edit-WinCollect {
    try {
        Stop-Service -Name WinCollect -PassThru -ErrorAction Stop
    }
    catch {
        Write-Output $_.Exception.Message 
        Write-Output "Oh noes"
        Pause
        exit 5
        #Write-Output $_.FullyQualifiedErrorID.Split(',')[0]
    }

    (Get-Content -Path "$configPath$configFile") | ForEach-Object {$_ -Replace $oldIP, $newIP} | Set-Content -Path "$configPath$configFile"
    Move-Item -Force -Path "$configPath$configPEM" -Destination "$configPath$configPEM.old" -PassThru
    
    try {
        Start-Service -Name WinCollect -PassThru -ErrorAction Stop
        Write-Output "Success"
        Pause
        exit 0
    }
    catch {
        Write-Output $_.Exception.Message 
        Write-Output "Can't restart service"
        Pause
        exit 5
        #Write-Output $_.FullyQualifiedErrorID.Split(',')[0]
    }
   
}

Edit-WinCollect
