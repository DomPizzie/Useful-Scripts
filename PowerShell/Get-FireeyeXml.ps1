<#
    .SYNOPSIS
    Pareses Fireeye XML and returns relevant info. 

    .DESCRIPTION
    Gathers all of the headers an analyst needs to perform an investigation.
    
    .PARAMETER Path
    Specifies the filePath to read. A default value is provided.

    .INPUTS
    System.Array

    .OUTPUTS
    System.String to file.

    .EXAMPLE
    C:\PS> Get-FireeyeXML.ps1

    .EXAMPLE
    C:\PS> Get-FireeyeXML.ps1 -Path <filePath>

    .EXAMPLE
    C:\PS> Get-FireeyeXML.ps1 <filePath>

    .NOTES
    Author:     Dominique Pizzie 
    Verion:     0.2
    Created:    03/16/2019
    Modified:   06/07/2019

    Copyright (c) 2019, Dominique Pizzie
    Copyrights licensed under the MIT License (MIT).
    See the accompanying LICENSE file for terms.
#>

param (
    # Specifies a path to one or more locations to read Fireeye XML files. Wildcards are permitted.
    [Parameter(Mandatory = $false,
        HelpMessage = 'Path to one or more locations to read Fireeye XML.')]
    [ValidateNotNullOrEmpty()]
    #[SupportsWildcards()]
    [alias('FilePath')]
    [string[]]
    $Path = "$HOME\Desktop\FireEye XML Parser Input\*.xml" 
)

#requires -version 2
Set-StrictMode -Version Latest

function Read-XML {
    return Get-Content -Path $Path
}

# $($fireeyeXML.alerts.alert.'smtp-message'.'smtp-header' -match 'X-Sender:\s+([\w\.@]+)').matches
function Write-XML {
    $innerXML = $fireeyeXML.alerts.alert
    $malwareInfo = $innerXML.explanation.'malware-detected'.malware

    switch ($innerXML.product) {
        'Web MPS' {
            $cncInfo = $innerXML.explanation.'cnc-services'.'cnc-service'
            if ($malwareInfo.name -eq 'Phish.URL' -and $malwareInfo.stype -eq 'bot-command') {
                $alertInfo = "Host: $cncInfo.host`n"
            }
            Write-Output "Date Investigated: $(Get-Date)

Source IP:Port = $($innerXML.src.ip):$($innerXML.src.port)
Source Hostname = $($innerXML.src.host)
Source MAC = $($innerXML.src.mac)

Destination IP:Port = $($innerXML.dst.ip):$($innerXML.dst.port)
Destination MAC = $($innerXML.dst.mac)
Action = $($innerXML.action)

CNC Host = $($cncInfo.host)
CNC address = $($cncInfo.address)
CNC Channel = $(($cncInfo.channel -split 'Accept: ')[0])
            " | Out-File -FilePath "$HOME\Desktop\fireeye_inc.txt"
            break
        }
        'Email MPS' {
			$ErrorActionPreference = 'SilentlyContinue'
            $smtpHeader = $innerXML.'smtp-message'.'smtp-header'.Split("`n")  #| Tee-Object -FilePath '$HOME\$alert $($innerXML.src.'smtp-mail-from')'
            $smtpHeaderData = $smtpHeader | Select-String -Pattern 'X-Sender: (.*)', 'X-Sender-IP: (.*)', 'From: (.*)', 'X-Orig-To: (.*)', 'X-Sender-Id: (.*)', 'X-Orig-To: (.*)', 'X-Authenticated-Sender: (.*)' | ForEach-Object {$_.matches[0].Groups[0].value} | Out-String
            #$malwareInfo.name
            if ($malwareInfo.stype -eq 'ehdr') {
                $alertInfo = 'Type: Yara'
            }
            elseif (($malwareInfo.name -eq 'Phish.URL' -or $malwareInfo.name -eq 'Local.Infection') -and $malwareInfo.stype -eq 'known-url') {
                $alertInfo = "Phish URL: $($innerXML.src.url)"
            }
            elseif ($malwareInfo.name -match '^Malware') {
                $alertInfo = "File Name/Hash: $($malwareInfo.original)/$($malwareInfo.md5sum)"
            }
            else {
                $alertInfo = 'UNKNOWN Type Error. Contact code maintainer'
            }
            #$smtpHeaderData | Get-Member
            Write-Output "$alert $($innerXML.src.'smtp-mail-from')

Datetime Recieved: $($innerXML.'smtp-message'.date)
Subject: $($innerXML.'smtp-message'.subject)
$($smtpHeaderData.Trim())
To: $($innerXML.dst.'smtp-to')
$alertInfo
All Indicators: <>
Indicators to Block: <>
30 Day search result: <>
Number of Email from Sender in past 30 days: <>
Additional findings: <>
            " | Out-File -FilePath "$HOME\Desktop\fireeye_inc.txt"
            break
        }
        Default {Write-Output 'Unknown'}
    }
} 


[string]$alert = 'FireEye Alert: FireEye Email Alert from'
[xml]$fireeyeXML = Read-XML
Write-XML
Start-Process notepad.exe "$HOME\Desktop\fireeye_inc.txt"
