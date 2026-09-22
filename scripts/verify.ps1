[CmdletBinding()]
param(
    [switch]$Full
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Invoke-Checked {
    param(
        [Parameter(Mandatory)] [string]$Label,
        [Parameter(Mandatory)] [scriptblock]$Action
    )
    Write-Host "== $Label =="
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE."
    }
}

$components = Get-Content -Raw -Encoding UTF8 (Join-Path $repoRoot 'components.json') | ConvertFrom-Json
if (@($components.components).Count -ne 2) {
    throw 'The suite must contain exactly two direct plugin parents.'
}

Invoke-Checked -Label 'Synchronize recursive submodule URLs' -Action {
    & git -C $repoRoot submodule sync --recursive
}
Invoke-Checked -Label 'Initialize pinned recursive submodules' -Action {
    & git -C $repoRoot submodule update --init --recursive
}

$directStatus = @(& git -C $repoRoot submodule status)
if ($LASTEXITCODE -ne 0 -or $directStatus.Count -ne 2) {
    throw "Expected 2 direct plugin submodules, found $($directStatus.Count)."
}
$recursiveStatus = @(& git -C $repoRoot submodule status --recursive)
if ($LASTEXITCODE -ne 0 -or $recursiveStatus.Count -ne 8) {
    throw "Expected 8 total recursive submodules, found $($recursiveStatus.Count)."
}
foreach ($line in $recursiveStatus) {
    if ($line[0] -in @('-', '+', 'U')) {
        throw "Submodule is missing or differs from the pinned parent commit: $line"
    }
}

$requiredFiles = @(
    'plugins/easyeda-ai-plugin/plugin.json',
    'plugins/easyeda-ai-plugin/components.json',
    'plugins/easyeda-ai-plugin/.gitmodules',
    'plugins/easyeda-ai-plugin/README.md',
    'plugins/easyeda-ai-plugin/README.en.md',
    'plugins/easyeda-api-plugin/package.json',
    'plugins/easyeda-api-plugin/components.json',
    'plugins/easyeda-api-plugin/README.md',
    'plugins/easyeda-api-plugin/README.en.md'
)
foreach ($relativePath in $requiredFiles) {
    if (-not (Test-Path (Join-Path $repoRoot $relativePath))) {
        throw "Required suite file is missing: $relativePath"
    }
}

$aiManifest = Get-Content -Raw -Encoding UTF8 (Join-Path $repoRoot 'plugins/easyeda-ai-plugin/plugin.json') | ConvertFrom-Json
$apiManifest = Get-Content -Raw -Encoding UTF8 (Join-Path $repoRoot 'plugins/easyeda-api-plugin/package.json') | ConvertFrom-Json
$aiDeclared = @($components.components | Where-Object name -eq 'easyeda-ai-plugin')
$apiDeclared = @($components.components | Where-Object name -eq 'easyeda-api-plugin')
if ($aiDeclared.Count -ne 1 -or $aiDeclared[0].version -ne $aiManifest.version) {
    throw 'AI plugin version does not match suite components.json.'
}
if ($apiDeclared.Count -ne 1 -or $apiDeclared[0].version -ne $apiManifest.version) {
    throw 'API plugin version does not match suite components.json.'
}

if ($Full) {
    Invoke-Checked -Label 'Full AgentDock AI plugin verification' -Action {
        & pwsh -NoProfile -File (Join-Path $repoRoot 'plugins/easyeda-ai-plugin/scripts/verify.ps1')
    }
    Invoke-Checked -Label 'API plugin locked dependencies' -Action {
        Push-Location (Join-Path $repoRoot 'plugins/easyeda-api-plugin')
        try { & npm run bootstrap }
        finally { Pop-Location }
    }
    Invoke-Checked -Label 'API plugin production dependency audit' -Action {
        Push-Location (Join-Path $repoRoot 'plugins/easyeda-api-plugin')
        try {
            & npm --prefix gateway-enhanced audit --omit=dev
            if ($LASTEXITCODE -ne 0) { throw 'Gateway production dependency audit failed.' }
            & npm --prefix bridge-server audit --omit=dev
            if ($LASTEXITCODE -ne 0) { throw 'Bridge production dependency audit failed.' }
        }
        finally { Pop-Location }
    }
    Invoke-Checked -Label 'API plugin tests' -Action {
        Push-Location (Join-Path $repoRoot 'plugins/easyeda-api-plugin')
        try { & npm test }
        finally { Pop-Location }
    }
    Invoke-Checked -Label 'API plugin extension package' -Action {
        Push-Location (Join-Path $repoRoot 'plugins/easyeda-api-plugin')
        try { & npm run package:extension }
        finally { Pop-Location }
    }
}

Write-Host "Verified EasyEDA plugin suite with 2 direct and 8 total recursive submodules."
