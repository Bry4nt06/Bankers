param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceUrl = "https://raw.githubusercontent.com/dwmk/RobloxGames/main/BrokenPVPgame_20240713_01.rbxl"
$targetPath = Join-Path $repoRoot "BankersPvPBrokenBase.rbxl"
$expectedGitBlobSha = "455079b30c13fd5037f049ee83a3a8b90cd5e1e9"
$expectedSize = 13471087
$tempPath = Join-Path $env:TEMP "Bankers-BrokenPVPgame_20240713_01.rbxl"

Write-Host "[BankersBrokenBootstrap] source: $sourceUrl"
Write-Host "[BankersBrokenBootstrap] target: $targetPath"

if ((Test-Path $targetPath) -and -not $Force) {
    $existingSize = (Get-Item $targetPath).Length
    if ($existingSize -eq $expectedSize) {
        $existingBlob = (& git hash-object -- $targetPath).Trim()
        if ($LASTEXITCODE -eq 0 -and $existingBlob -eq $expectedGitBlobSha) {
            Write-Host "[BankersBrokenBootstrap] donor already installed and verified."
            exit 0
        }
    }
    throw "BankersPvPBrokenBase.rbxl already exists but does not match the pinned Broken snapshot. Re-run with -Force to replace it."
}

if (Test-Path $tempPath) {
    Remove-Item $tempPath -Force
}

Write-Host "[BankersBrokenBootstrap] downloading pinned Broken PvP snapshot..."
Invoke-WebRequest -Uri $sourceUrl -OutFile $tempPath -UseBasicParsing

$downloadedSize = (Get-Item $tempPath).Length
if ($downloadedSize -ne $expectedSize) {
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    throw "Downloaded donor size mismatch. Expected $expectedSize bytes, got $downloadedSize."
}

$blobSha = (& git hash-object -- $tempPath).Trim()
if ($LASTEXITCODE -ne 0) {
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    throw "git hash-object failed while verifying the Broken donor."
}
if ($blobSha -ne $expectedGitBlobSha) {
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    throw "Broken donor verification failed. Expected Git blob $expectedGitBlobSha, got $blobSha."
}

if ((Test-Path $targetPath) -and $Force) {
    Remove-Item $targetPath -Force
}
Move-Item $tempPath $targetPath

Write-Host ""
Write-Host "[BankersBrokenBootstrap] COMPLETE"
Write-Host "[BankersBrokenBootstrap] verified Git blob: $blobSha"
Write-Host "[BankersBrokenBootstrap] installed: $targetPath"
Write-Host ""
Write-Host "Open BankersPvPBrokenBase.rbxl directly in Roblox Studio."
Write-Host "Do NOT connect pvp.project.json to this donor base; that project is the earlier clean-room prototype and can overwrite donor StarterPlayerScripts."
Write-Host "The next Bankers pass will retain Broken's complete combat/movement/gun systems, keep one donor map, and remove the unused maps/branding around that foundation."
