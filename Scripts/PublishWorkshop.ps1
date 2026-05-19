param(
    [string]$SteamUsername,
    [string]$PublishedFileId,
    [ValidateSet('Public', 'FriendsOnly', 'Private', 'Unlisted')]
    [string]$Visibility = 'Public',
    [string]$ChangeNote = 'Initial release',
    [switch]$PrepareOnly,
    [string]$SteamCmdDir = (Join-Path $env:LOCALAPPDATA 'CodexTools\steamcmd')
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$workshopRoot = Join-Path $repoRoot '.workshop'
$contentDir = Join-Path $workshopRoot 'content'
$vdfPath = Join-Path $workshopRoot 'workshop_item.vdf'
$publishedFileIdPath = Join-Path $repoRoot 'About\PublishedFileId.txt'

function ConvertTo-VdfString {
    param([string]$Value)
    return ($Value -replace '\\', '/') -replace '"', '\"'
}

function Copy-ModContent {
    if (Test-Path -LiteralPath $contentDir) {
        Remove-Item -LiteralPath $contentDir -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $contentDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'About') -Destination $contentDir -Recurse
    Copy-Item -LiteralPath (Join-Path $repoRoot '1.6') -Destination $contentDir -Recurse
    Copy-Item -LiteralPath (Join-Path $repoRoot 'LoadFolders.xml') -Destination $contentDir
    Copy-Item -LiteralPath (Join-Path $repoRoot 'README.md') -Destination $contentDir
}

function Ensure-SteamCmd {
    $steamCmdExe = Join-Path $SteamCmdDir 'steamcmd.exe'
    if (Test-Path -LiteralPath $steamCmdExe) {
        return $steamCmdExe
    }

    New-Item -ItemType Directory -Force -Path $SteamCmdDir | Out-Null
    $zipPath = Join-Path $SteamCmdDir 'steamcmd.zip'

    Invoke-WebRequest `
        -Uri 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip' `
        -OutFile $zipPath

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $SteamCmdDir)

    return $steamCmdExe
}

$visibilityValue = @{
    Public = '0'
    FriendsOnly = '1'
    Private = '2'
    Unlisted = '3'
}[$Visibility]

if ([string]::IsNullOrWhiteSpace($PublishedFileId)) {
    if (Test-Path -LiteralPath $publishedFileIdPath) {
        $PublishedFileId = (Get-Content -Raw -LiteralPath $publishedFileIdPath).Trim()
    }
    else {
        $PublishedFileId = '0'
    }
}

Copy-ModContent

$title = 'VFE Classical - Centurion Armor Performance Patch'
$description = 'Fixes VFE Classical''s horrendous performance issue with centurion armor by making the aura buff update every 5 seconds instead of every tick. The buff still works the same, but the performance impact should be non-existent.'
$previewPath = Join-Path $contentDir 'About\Preview.png'

$vdf = @"
"workshopitem"
{
    "appid" "294100"
    "publishedfileid" "$(ConvertTo-VdfString $PublishedFileId)"
    "contentfolder" "$(ConvertTo-VdfString $contentDir)"
    "previewfile" "$(ConvertTo-VdfString $previewPath)"
    "visibility" "$visibilityValue"
    "title" "$(ConvertTo-VdfString $title)"
    "description" "$(ConvertTo-VdfString $description)"
    "changenote" "$(ConvertTo-VdfString $ChangeNote)"
    "tags"
    {
        "0" "Mod"
        "1" "1.6"
    }
}
"@

New-Item -ItemType Directory -Force -Path $workshopRoot | Out-Null
Set-Content -LiteralPath $vdfPath -Value $vdf -Encoding UTF8

Write-Host "Prepared Workshop content: $contentDir"
Write-Host "Prepared Workshop VDF:     $vdfPath"

if ($PrepareOnly) {
    Write-Host 'PrepareOnly set; not running SteamCMD.'
    exit 0
}

if ([string]::IsNullOrWhiteSpace($SteamUsername)) {
    throw 'Pass -SteamUsername <your Steam username>, or use -PrepareOnly to only generate the VDF.'
}

$steamCmdExe = Ensure-SteamCmd

Write-Host ''
Write-Host 'SteamCMD will prompt for your Steam password and Steam Guard code if needed.'
Write-Host 'If this is the first publish, leave -PublishedFileId at 0. SteamCMD should update the VDF with the new ID.'
Write-Host ''

& $steamCmdExe +login $SteamUsername +workshop_build_item $vdfPath +quit
