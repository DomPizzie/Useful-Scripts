<#
    .SYNOPSIS
    Grabs all URL Request from browser HAR file(s)

    .DESCRIPTION
    Gathers the URLs out of requsted file and dedups them. Content is saved to csv textfile.

    .INPUTS
    HAR file.

    .OUTPUTS
    Plain text file with URLs newline delimited

    .EXAMPLE
    C:\PS> parseHAR.ps1 filepath

    .NOTES
    Copyright (c) 2018, Dominique Pizzie
    Copyrights licensed under the MIT License (MIT).
    See the accompanying LICENSE file for terms.

    .LINK
#>

Param(
    [Parameter(Mandatory=$true)][string[]]$filePath
)

#Requires -Version 3.0
Set-StrictMode -Version Latest

$fileInput = Select-String -Path $filePath -Pattern '"url": "(http.*)"'

$fileInput | ForEach-Object -Process {
    $_.Matches.Groups[1].Value
} | Sort-Object -Unique | Out-File -FilePath ./outputHAR.csv
