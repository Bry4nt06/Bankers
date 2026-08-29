param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceUrl = "https://raw.githubusercontent.com/dwmk/RobloxGames/main/BrokenPVPgame_20240713_01.rbxl"
$targetPath = Join-Path $repoRoot "BankersPvPBrokenBase.rbxl"

# GitHub's contents metadata for this large binary reports blob
# 455079b30c13fd5037f049ee83a3a8b90cd5e1e9, but the actual bytes served by
# raw.githubusercontent.com hash to the value below. Bankers installs the raw
# representation, so verification must pin the representation we actually use.
$upstreamMetadataBlobSha = "455079b30c13fd5037f049ee83a3a8b90cd5e1e9"
$expectedRawGitBlobSha = "2f5759dd5bcc23dc8e3d006c95543f1e051f77ed"
$expectedSize = 13471087
$tempPath = Join-Path $env:TEMP "Bankers-BrokenPVPgame_20240713_01.rbxl"

function Get-GitBlobSha([string]$Path) {
    $value = (& git hash-object -- $Path).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($value)) {
        throw "git hash-object failed while verifying '$Path'."
    }
    return $value
}

function Assert-BrokenSnapshot([string]$Path) {
    if (-not (Test-Path $Path)) {
        throw "Broken donor snapshot was not found at '$Path'."
    }

    $size = (Get-Item $Path).Length
    if ($size -ne $expectedSize) {
        throw "Broken donor size mismatch. Expected $expectedSize bytes, got $size."
    }

    $blobSha = Get-GitBlobSha $Path
    if ($blobSha -ne $expectedRawGitBlobSha) {
        throw "Broken donor verification failed. Expected raw Git blob $expectedRawGitBlobSha, got $blobSha."
    }

    return $blobSha
}

Write-Host "[BankersBrokenBootstrap] source: $sourceUrl"
Write-Host "[BankersBrokenBootstrap] target: $targetPath"
Write-Host "[BankersBrokenBootstrap] upstream metadata blob: $upstreamMetadataBlobSha"
Write-Host "[BankersBrokenBootstrap] pinned raw blob: $expectedRawGitBlobSha"

if ((Test-Path $targetPath) -and -not $Force) {
    try {
        $existingBlob = Assert-BrokenSnapshot $targetPath
        Write-Host "[BankersBrokenBootstrap] donor already installed and verified: $existingBlob"
        exit 0
    }
    catch {
        throw "BankersPvPBrokenBase.rbxl already exists but does not match the pinned Broken raw snapshot. Re-run with -Force to replace it. Details: $($_.Exception.Message)"
    }
}

if (Test-Path $tempPath) {
    Remove-Item $tempPath -Force
}

Write-Host "[BankersBrokenBootstrap] downloading pinned Broken PvP snapshot..."
Invoke-WebRequest -Uri $sourceUrl -OutFile $tempPath -UseBasicParsing

try {
    $blobSha = Assert-BrokenSnapshot $tempPath
}
catch {
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    throw
}

if ((Test-Path $targetPath) -and $Force) {
    Remove-Item $targetPath -Force
}
Move-Item $tempPath $targetPath

Write-Host ""
Write-Host "[BankersBrokenBootstrap] COMPLETE"
Write-Host "[BankersBrokenBootstrap] verified raw Git blob: $blobSha"
Write-Host "[BankersBrokenBootstrap] verified size: $expectedSize bytes"
Write-Host "[BankersBrokenBootstrap] installed: $targetPath"
Write-Host ""
Write-Host "Open BankersPvPBrokenBase.rbxl directly in Roblox Studio."
Write-Host "Do NOT connect pvp.project.json to this donor base; that project is the earlier clean-room prototype and can overwrite donor StarterPlayerScripts."
Write-Host "The next Bankers pass will retain Broken's complete combat/movement/gun systems, keep one donor map, and remove the unused maps/branding around that foundation."
