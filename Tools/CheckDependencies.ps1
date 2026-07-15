<#
.SYNOPSIS
    Checks that all dependencies in the repository exist
.DESCRIPTION
    This script intends to help ensure that all dependencies in the repository are
    existing package identifiers with the correct casing.

    It will parse through each of the manifest files and then run a search against
    WinGet to check that the identifier exists.
.EXAMPLE
    PS C:\Projects\winget-pkgs> Get-Help .\Tools\CheckDependencies.ps1 -Full
    Show this script's help
.EXAMPLE
    PS C:\Projects\winget-pkgs> .\Tools\CheckDependencies.ps1
    Run the script to output non-existent dependencies
.NOTES
    Please file an issue if you run into errors with this script:
    https://github.com/microsoft/winget-pkgs/issues
.LINK
    https://github.com/microsoft/winget-pkgs/blob/master/Tools/CheckDependencies.ps1
#>
#Requires -Version 5

[CmdletBinding()]
param (
    [switch] $Offline
)

$ProgressPreference = 'SilentlyContinue'

Import-Module (Join-Path $PSScriptRoot 'Modules\SharedUtils\SharedUtils.psd1') -Force

Initialize-RequiredModule -Name 'powershell-yaml'
Initialize-RequiredModule -Name 'Microsoft.WinGet.Client' -MinimumVersion '1.9.2411'

$ManifestsFolder = Get-ManifestsFolder -ScriptRoot $PSScriptRoot

Write-Verbose "Fetching list of installer manifests from $ManifestsFolder . . ."
$installerManifests = Get-ChildItem $ManifestsFolder -Recurse -Filter '*.installer.yaml'
Write-Verbose "Found $($installerManifests.Count) manifests"
Write-Verbose 'Filtering manifests for Package Dependencies. . .'
$manifestsWithPackageDependencies = $installerManifests.Where({ $_ | Get-Content -Raw | Select-String 'PackageDependencies' })
Write-Verbose "$($manifestsWithPackageDependencies.Count) manifests contain dependencies"
Write-Verbose 'Parsing manifest contents. . .'
$dependenciesByManifest = $manifestsWithPackageDependencies | ForEach-Object {
    $YamlContent = $_ | Get-Content | ConvertFrom-Yaml
    return @{
        Package      = $YamlContent.PackageIdentifier
        Version      = $YamlContent.PackageVersion
        Dependencies = $YamlContent.Dependencies.PackageDependencies
    }
}
Write-Verbose 'Filtering out dependency Package Identifiers. . .'
$dependencyIdentifiers = $dependenciesByManifest.Dependencies | ForEach-Object { $_.PackageIdentifier } | Select-Object -Unique
Write-Verbose "Found $($dependencyIdentifiers.Count) unique dependencies"
Write-Verbose 'Checking for the existence of dependencies. . .'
if ($Offline) { Write-Verbose 'Offline mode selected. Local manifests names will be used instead of querying the WinGet source' }
$dependenciesWithStatus = $dependencyIdentifiers | ForEach-Object {
    Write-Debug "Checking for $_"
    if ($Offline) {
        $exists = $null -ne $($installerManifests.Name -cmatch [regex]::Escape($_))
    } else {
        $exists = $null -ne $(Find-WinGetPackage -Id $_ -MatchOption Equals)
    }
    Write-Debug "winget search result: $($exists)"
    return @{
        Identifier = $_
        Exists     = $exists
    }
}
Write-Verbose 'Filtering out dependencies which have been found. . .'
$unmetDependencies = $dependenciesWithStatus.Where({ !($_.Exists) })
Write-Verbose "$($unmetDependencies.Count) dependencies were not found"
Write-Output $unmetDependencies.Identifier
if ($unmetDependencies) { exit 1 }

