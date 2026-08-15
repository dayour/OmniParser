<#
.SYNOPSIS
    Syncs this folder's file_inventory.csv with the central docs folder.

.DESCRIPTION
    Each documented folder keeps its own file_inventory.csv next to the
    scripts it describes, and the central copy lives under
    <repo>\docs\inventory\<slug>\file_inventory.csv.

    Push (default) copies the local CSV up to docs. Pull copies the docs copy
    back down, which is how a folder picks up an inventory someone regenerated
    centrally.

    The slug subfolder exists so robocopy can be used as intended -- directory to
    directory with a filename filter. Robocopy cannot rename a file in transit,
    so giving every location its own subfolder is what lets all ten copies keep
    the same filename without colliding.

.PARAMETER Pull
    Reverse the direction: refresh the local CSV from the central docs copy.

.PARAMETER WhatIf
    List what would be transferred without copying anything.

.EXAMPLE
    .\docs_robocopy.ps1
    Push this folder's inventory up to docs.

.EXAMPLE
    .\docs_robocopy.ps1 -Pull
    Refresh this folder's inventory from docs.
#>
[CmdletBinding()]
param(
    [switch]$Pull,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$Slug     = 'OmniParser_eval'
$FileName = 'file_inventory.csv'

# Locate the repository root by walking up from this script. We keep walking to
# the drive root and remember the OUTERMOST directory containing a .git entry
# rather than stopping at the first one: BitNet and OmniParser are submodules
# and each carries its own .git file, so stopping early would resolve the root
# to a submodule and write the docs folder into the wrong repository.
function Get-RepoRoot {
    param([string]$Start)
    $dir = Get-Item -LiteralPath $Start
    $found = $null
    while ($null -ne $dir) {
        if (Test-Path -LiteralPath (Join-Path $dir.FullName '.git')) { $found = $dir.FullName }
        $dir = $dir.Parent
    }
    return $found
}

$repoRoot = Get-RepoRoot -Start $PSScriptRoot
if (-not $repoRoot) {
    Write-Error "Could not locate the repository root (no .git found above '$PSScriptRoot')."
    exit 1
}

$localDir  = $PSScriptRoot
$docsDir   = Join-Path $repoRoot "docs\inventory\$Slug"

if ($Pull) {
    $source      = $docsDir
    $destination = $localDir
    $direction   = "docs -> local"
} else {
    $source      = $localDir
    $destination = $docsDir
    $direction   = "local -> docs"
}

if (-not (Test-Path -LiteralPath (Join-Path $source $FileName))) {
    Write-Error "Nothing to sync: '$FileName' not found in '$source'."
    exit 1
}

New-Item -ItemType Directory -Force -Path $destination | Out-Null

Write-Host "Syncing $FileName  ($direction)"
Write-Host "  from : $source"
Write-Host "  to   : $destination"

$roboArgs = @($source, $destination, $FileName, '/NJH', '/NJS', '/NDL', '/NP', '/R:2', '/W:2')
if ($WhatIf) { $roboArgs += '/L' }

& robocopy.exe @roboArgs | Out-Null
$code = $LASTEXITCODE

# Robocopy does NOT use 0 for success. It returns a bitmask where 0-7 are all
# successful outcomes -- 0 means nothing needed copying and 1 means files were
# copied, so treating a non-zero exit as failure would report every successful
# sync as an error. Only 8 and above are genuine failures.
if ($code -ge 8) {
    Write-Error "robocopy failed with exit code $code."
    exit $code
}

switch ($code) {
    0       { Write-Host "Already up to date." }
    1       { Write-Host "Copied." }
    default { Write-Host "Completed (robocopy code $code)." }
}

exit 0
