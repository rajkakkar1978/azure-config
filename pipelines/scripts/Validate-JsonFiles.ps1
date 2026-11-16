[CmdletBinding()]
param(
    [string]$Path
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Path)) {
    $Path = Join-Path (Split-Path -Parent $PSScriptRoot) 'projects'
}

$resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction Stop
if (-not (Test-Path -LiteralPath $resolvedPath.Path -PathType Container)) {
    throw "JSON validation path is not a directory: $Path"
}

$jsonFiles = @(Get-ChildItem -LiteralPath $resolvedPath.Path -Filter '*.json' -File -Recurse -ErrorAction Stop)
if ($jsonFiles.Count -eq 0) {
    throw "No JSON files were found under: $($resolvedPath.Path)"
}

$invalidFiles = @()
foreach ($file in $jsonFiles) {
    try {
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) {
            throw 'The file is empty.'
        }

        $null = ConvertFrom-Json -InputObject $content -ErrorAction Stop
    }
    catch {
        $invalidFiles += [pscustomobject]@{
            Path  = $file.FullName
            Error = $_.Exception.Message
        }
    }
}

if ($invalidFiles.Count -gt 0) {
    $details = @($invalidFiles | ForEach-Object { " - $($_.Path): $($_.Error)" }) -join [Environment]::NewLine
    throw "JSON validation failed for $($invalidFiles.Count) of $($jsonFiles.Count) file(s):$([Environment]::NewLine)$details"
}

Write-Host "Validated $($jsonFiles.Count) JSON file(s) under $($resolvedPath.Path)."
