$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$managedDir = 'C:\Program Files (x86)\Steam\steamapps\common\RimWorld\RimWorldWin64_Data\Managed'
$toolVersion = '4.8.0'
$toolRoot = Join-Path $env:LOCALAPPDATA "CodexTools\Microsoft.Net.Compilers.Toolset.$toolVersion"
$packagePath = "$toolRoot.nupkg"
$cscPath = Join-Path $toolRoot 'tasks\net472\csc.exe'

if (-not (Test-Path -LiteralPath $cscPath)) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $toolRoot) | Out-Null
    Invoke-WebRequest `
        -Uri "https://www.nuget.org/api/v2/package/Microsoft.Net.Compilers.Toolset/$toolVersion" `
        -OutFile $packagePath

    if (Test-Path -LiteralPath $toolRoot) {
        Remove-Item -LiteralPath $toolRoot -Recurse -Force
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($packagePath, $toolRoot)
}

$sourceFiles = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'Source\VFECCenturionArmorPatch') -Filter '*.cs' -File |
    ForEach-Object { $_.FullName }

$outputPath = Join-Path $repoRoot '1.6\Assemblies\VFECCenturionArmorPatch.dll'

& $cscPath `
    /nologo `
    /target:library `
    /optimize+ `
    /debug- `
    /langversion:7.3 `
    /nostdlib+ `
    /reference:"$managedDir\mscorlib.dll" `
    /reference:"$managedDir\System.dll" `
    /reference:"$managedDir\System.Core.dll" `
    /reference:"$managedDir\Assembly-CSharp.dll" `
    /out:$outputPath `
    $sourceFiles

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Built $outputPath"
