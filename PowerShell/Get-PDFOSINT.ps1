#requires -version 2

<#
    .SYNOPSIS
    Parses PDF for IOCs and returns it as a text file with markdown syntax.

    .DESCRIPTION
    All PDF(s) in specified "-Path" are read and txt files are created in $Path.
    These text files are then read line-by-line until EOF, or a specified string is matched.
    Read data is saved to an array variable and parsed line-by-line looking for strings that match regex.
    Collected domains, URLs, IPs, and emails are then saved to a txt file on ~/Desktop with markdown syntax.
    
    .PARAMETER Path
    Specifies the filePath to read. A default value is provided.

    .INPUTS
    None

    .OUTPUTS
    System.String to file.

    .EXAMPLE
    C:\PS> Get-PdfIOC.ps1

    .EXAMPLE
    C:\PS> Get-PdfIOC.ps1 -Path <filePath>

    .EXAMPLE
    C:\PS> Get-PdfIOC.ps1 <filePath>

    .LINK
    https://www.reddit.com/r/PowerShell/comments/7yee0i/how_do_i_parse_pdf_text_with_powershell/
    http://www.beefycode.com/post/ConvertFrom-PDF-Cmdlet.aspx
    https://www.powershellgallery.com/packages/Convert-PDF/1.0/Content/Convert-PDF.psm1
    https://www.xpdfreader.com/pdftotext-man.html
    https://www.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch04s01.html
    https://www.regular-expressions.info/email.html
    https://www.regular-expressions.info/ip.html
    
    .NOTES
    Author:     Dominique Pizzie 
    Verion:     0.1
    Created:    05/28/2019
    Modified:   05/30/2019

    Copyright (c) 2019, Dominique Pizzie
    Copyrights licensed under the MIT License (MIT).
    See the accompanying LICENSE file for terms.
#>

### Parameters ###

param (
    # Specifies a path to read all PDF files. Wildcards are permitted.
    [Parameter(Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = 'Path to one or more locations to read PDF file.')]
    [ValidateNotNullOrEmpty()]
    #[SupportsWildcards()] ### Not PS 2 compliant
    [alias('FilePath')]
    [string[]]
    $Path = "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\"
)
### Initialisations ###

Set-StrictMode -Version Latest
#$ErrorActionPreference = 'SilentlyContinue'

### Declarations ### 

### Functions ###

# Uses pdftotext.exe to create txt files of each PDF, see Links in help
function ConvertTo-PDFtoText {
    Write-Host "Reading PDF Files..."
    $pdfFiles | ForEach-Object {Start-Process -Wait -NoNewWindow -FilePath "$Path\pdftotext.exe" -ArgumentList '-nopgbrk','-raw',`"$_`"}
}

# Each txt file is then searched for patterns of interest
# Patterns are gathered in memory
function Write-Report {
    Write-Host "Parsing Data..."
    $reportName = @(Get-ChildItem -Path $Path -Filter *.txt)
    #write-host $(Select-String -Path $_.FullName -Pattern '^Findings?$') #| Select-Object -ExpandProperty Linenumber)
    $reportContent = $reportName | ForEach-Object {
        Write-Output "### $_ ###"
        $lineNumber = Select-String -Path $_.FullName -Pattern '^Findings?$' -List | Select-Object -ExpandProperty Linenumber
        if (!$lineNumber) {
            $lineNumber = 200
        } 
        Get-Content -Path $_.FullName -TotalCount $lineNumber
    }
    $hash = $reportContent | Select-String -Pattern "^[a-f0-9]{64}(?: \()?" | Sort-Object | Get-Unique
    $email = $reportContent | Select-String -Pattern '^<Redacted> <([a-z0-9.%+-]+\[?@\]?[a-z0-9.%+-]+\.[^>]+)>$','\b([A-Z0-9\[\].%+-]+?\[@\][A-Z0-9\[\].%+-]+?\[\.\][A-Z]{2,})\b' -CaseSensitive | ForEach-Object {$_.Matches[0].Groups[1].value} | Sort-Object | Get-Unique
    $domains = $reportContent | Select-String -Pattern '^([a-z0-9](?:[a-z0-9-]*\.)+?[a-z]{2,})$','\bHXXPS?:\/\/((?:[A-Z0-9-]+?\[\.\])+[A-Z]{2,})\b' -CaseSensitive | ForEach-Object {$_.Matches[0].Groups[1].value} | Sort-Object | Get-Unique
    $ip = $reportContent | Select-String -Pattern "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" | Sort-Object | Get-Unique
    
    Write-Output @"
# Reports
$($reportName -join ', ')

# Domains
$($domains -join [Environment]::NewLine)

# IP Addresses 
$($ip -join [Environment]::NewLine)

# Hashes
$($hash -join [Environment]::NewLine)

# Email Addresses
$($email -join [Environment]::NewLine)
"@
}

### Execution ###

# Supports PS Version 2
$pdfFiles = Get-ChildItem -Path $Path -Filter *.pdf | Select-Object -ExpandProperty FullName

# Create txt files from PDF files
ConvertTo-PDFtoText 

# Gathers matches and saves output to file
Write-Report | Out-File -FilePath "$HOME\Desktop\ReportIOC.txt"

Write-Host "Job Done"

# Cleans up txt files from directory
Remove-Item -Path "$Path*" -Filter *.txt
