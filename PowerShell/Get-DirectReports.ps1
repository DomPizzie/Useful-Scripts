#requires -version 2

### Parameters ###

### Initializations ###

Set-StrictMode -Version Latest
# $ErrorActionPreference = 'SilentlyContinue'

### Declarations ### 

### Functions ###

function Get-DirectReports {
    <#
    .SYNOPSIS
    Takes input of AD member, and outputs all direct reports.

    .DESCRIPTION
    By default, all direct reports of the specified user are returned. 
    The Depth parameter can be specified to search for all returned objects recursively.
    Use pipes to send to file if desired.
    
    .PARAMETER DistinguishedName
    Specifies the user to search for in AD.

    .PARAMETER Depth
    Specifies the depth in which to search for DirectReports.
    Default value of 1.

    .INPUTS
    None

    .OUTPUTS
    System.Object

    .EXAMPLE
    C:\PS> Get-DirectReports <ADUser>

    .EXAMPLE
    C:\PS> Get-DirectReports -DistinguishedName <ADUser>

    .EXAMPLE
    C:\PS> Get-DirectReports <ADUser> -Depth <byte>

    .EXAMPLE
    C:\PS> Get-DirectReports <ADUser> -Depth <byte> | Export-Csv $HOME/Desktop/direct_reports.csv -NoTypeInformation

    .LINK
    https://www.reddit.com/r/PowerShell/comments/ako1zy/org_chart_by_manager_field_in_ad/
    https://gallery.technet.microsoft.com/scriptcenter/Get-ADDirectReport-962616c6/view/Discussions#content
    https://stackoverflow.com/questions/4875912/determine-if-powershell-script-has-been-dot-sourced

    .NOTES
    Author:     Dominique Pizzie @DomPizzie
    Verion:     0.1
    Created:    06/05/2019
    Modified:   06/05/2019

    Copyright (c) 2019, Dominique Pizzie
    Copyrights licensed under the MIT License (MIT).
    See the accompanying LICENSE file for terms.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$DistinguishedName,
        [ValidateRange(0,99)]
        [byte]$Depth=1
    )

    if ($DistinguishedName -notmatch '(?:\s|\.)admin,') {
        if ($Depth) {
            Write-Verbose '2'
            $rootUser = Get-ADUser -Identity $DistinguishedName -Properties Manager,EmailAddress,DirectReports
            $rootUser | Select-Object -ExpandProperty directReports | 
                ForEach-Object -Begin { 
                    $rootUser | Select-Object Name,EmailAddress
                } -Process {
                    Get-Directreports $_ -Depth ($Depth-1)
                }
        } elseif (!$Depth) {
            Get-ADUser -Identity $DistinguishedName -Properties EmailAddress | 
                Select-Object Name,EmailAddress
        }
            # Can use the below to modify what object are returned
            <#
                Select-Object Name,EmailAddress,@{n="Manager";e={$_.Manager | 
                    foreach-object {($_ -split '^cn=([a-zA-Z]+),')[1]}}},@{n="DirectReports";e={$_.DirectReports | 
                        foreach-object {($_ -split '^cn=([a-zA-Z]+),')[1]}}} |
                    Format-Table
                $results | Out-File <filename>
            #>
    }
}

### Execution ###

# This will not be utilized if script is dot sourced or added into a module
$isDotSourced = $MyInvocation.InvocationName -eq '.' # -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    [string]$name = Read-Host -Prompt 'Enter user account to search'
    [byte]$depth = Read-Host -Prompt 'Enter depth to search'

    if ($null -ne $depth -and $depth -ge 1) {
        Get-DirectReports -DistinguishedName $name -Depth $depth | Export-Csv $HOME/Desktop/direct_reports.csv -NoTypeInformation
    } else {
        Get-DirectReports -DistinguishedName $name | Export-Csv $HOME/Desktop/direct_reports.csv -NoTypeInformation
    }
}
