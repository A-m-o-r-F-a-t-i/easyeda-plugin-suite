[CmdletBinding()]
param(
    [switch]$Remote
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$directPaths = @('plugins/easyeda-ai-plugin', 'plugins/easyeda-api-plugin')

& git -C $repoRoot submodule sync --recursive
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to synchronize submodule URLs.'
}

if ($Remote) {
    foreach ($path in $directPaths) {
        & git -C $repoRoot submodule update --init --remote --merge -- $path
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update direct plugin submodule: $path"
        }
    }
    & git -C $repoRoot submodule update --init --recursive
}
else {
    & git -C $repoRoot submodule update --init --recursive
}

if ($LASTEXITCODE -ne 0) {
    throw 'Failed to initialize recursive submodules.'
}

& git -C $repoRoot submodule status --recursive
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to read recursive submodule status.'
}
