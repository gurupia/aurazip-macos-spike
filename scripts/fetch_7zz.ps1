#requires -Version 5.1
<#
.SYNOPSIS
    AuraZip non-Windows `7zz` prebuilt fetcher.

.DESCRIPTION
    Downloads the official 7-Zip prebuilt console binary (`7zz`) for Linux/macOS
    into `binaries/7zz` so the app bundle can locate it via `locate_7zz()`.
    Version is pinned (default 26.06). Windows bundles `7z.dll` instead.

.PARAMETER Os
    linux | macos. Auto-detected from the host when omitted.

.PARAMETER Version
    Pinned 7-Zip version (default 26.06).

.PARAMETER OutputDir
    Output directory (default: <repo>/binaries).

.EXAMPLE
    pwsh -NoProfile -File scripts\fetch_7zz.ps1 -Os linux
    pwsh -NoProfile -File scripts\fetch_7zz.ps1 -Os macos
#>
[CmdletBinding()]
param(
    [ValidateSet('linux', 'macos')]
    [string]$Os,
    [string]$Version = '26.06',
    [string]$OutputDir = (Join-Path $PSScriptRoot '..\binaries')
)

$ErrorActionPreference = 'Stop'

if (-not $Os) {
    if ($IsWindows) {
        throw 'Windows bundles 7z.dll; pass -Os linux or -Os macos explicitly.'
    }
    if ($IsMacOS) { $Os = 'macos' } else { $Os = 'linux' }
}

$arch = 'x64'
$verTag = $Version -replace '\.', ''
$asset = if ($Os -eq 'linux') { "7z$verTag-linux-$arch.tar.xz" } else { "7z$verTag-mac.tar.xz" }
$url = "https://github.com/ip7z/7zip/releases/download/$Version/$asset"

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('aurazip-7zz-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$archive = Join-Path $tmp $asset

Write-Host "[fetch_7zz] download $url"
Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing

$extract = Join-Path $tmp 'extract'
New-Item -ItemType Directory -Path $extract | Out-Null
& tar -xf $archive -C $extract
if ($LASTEXITCODE -ne 0) { throw 'tar extraction failed' }

$bin = Get-ChildItem -Path $extract -Recurse -File -Filter '7zz' | Select-Object -First 1
if (-not $bin) { throw '7zz binary not found in archive' }

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$dest = Join-Path $OutputDir '7zz'
Copy-Item $bin.FullName $dest -Force
Remove-Item $tmp -Recurse -Force

Write-Host "[fetch_7zz] saved: $dest"
