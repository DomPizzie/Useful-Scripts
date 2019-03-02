<#
    .SYNOPSIS
    Decodes Proofpoint URLs and grabs domain and path. 

    .DESCRIPTION
    Decodes v1 and v2 versions of Proofpoint URLs. The results are outputted to console.

    .PARAMETER Path
    Specifies the filePath to read. A default value is provided.

    .INPUTS
    System.Array

    .OUTPUTS
    System.String to host.

    .EXAMPLE
    C:\PS> proofpoint_decode.ps1

    ================ Proofpoint Parser ================
    1: Read URL(s) from clipboard.
    2: Read URL(s) from file.
    q: Quit.
    
    Please make a selection:

    .EXAMPLE
    C:\PS> proofpoint_decode.ps1 -Path <filePath>

    ================ Proofpoint Parser ================
    1: Read URL(s) from clipboard.
    2: Read URL(s) from file.
    q: Quit.
    
    Please make a selection:

    .EXAMPLE
    C:\PS> proofpoint_decode.ps1 <filePath>

    ================ Proofpoint Parser ================
    1: Read URL(s) from clipboard.
    2: Read URL(s) from file.
    q: Quit.
    
    Please make a selection:

    .NOTES
    Author:     Dominique Pizzie 
    Verion:     0.1
    Modified:   03/02/2019

    Copyright (c) 2019, Dominique Pizzie
    Copyrights licensed under the MIT License (MIT).
    See the accompanying LICENSE file for terms.
#>

param (
    # Specifies a path to one or more locations to read Proofpoint URL(s). Wildcards are permitted.
    [Parameter(Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = 'Path to one or more locations to read Proofpoint URL(s).')]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [alias("FilePath")]
    [string[]]
    $Path = "$HOME\Documents\proofpoint_input.txt" 
)

#requires -version 2
Set-StrictMode -Version Latest

<#
    .SYNOPSIS
    Displays menu to user.

    .PARAMETER Title
    Title used for menu. A default value is provided.
#>
function Show-Menu ([string]$Title = 'Proofpoint Parser') {
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host '1: Read URL(s) from clipboard.'
    Write-Host '2: Read URL(s) from file.'
    Write-Host 'q: Quit.' -ForegroundColor Red
    Write-Host
}

<#
    .SYNOPSIS
    Read input and decode all valid Proofpoint URL(s).

    .PARAMETER UrlData
    Used to store input value to decode. 
#>
function Read-Proofpoint ([string[]]$UrlData) {

    [string[]]$result = ForEach ($url in $UrlData) {
        if ($url -match 'proofpoint\[?\.\]?com/v2/url\?u=(?<url>.+?)&(amp;)?[dc]=') {
            $conv = $Matches.url.Replace('_', '/').Replace('-', '%')
            [uri]::UnescapeDataString($conv)
        }
        elseif ($url -match 'proofpoint\[?\.\]?com/v1/url\?u=(?<url>.+?)&(amp;)?k=') {
            $Matches.url
        }
        else {
            'Not a valid Proofpoint URL.'
        }
    }
    $result
}

do {
    Show-Menu
    $selection = Read-Host 'Please make a selection'
    switch ($selection) {
        '1' { Read-Proofpoint -UrlData $(Get-Clipboard); Break }
        '2' { Read-Proofpoint -UrlData $(Get-Content $Path); Break }
        'q' { Return }
        default { Write-Host 'Try Again' }
    }   
    $null = Read-Host 'Press Enter to continue...'
} while ($true)